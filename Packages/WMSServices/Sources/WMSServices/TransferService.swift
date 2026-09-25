import Foundation
import WMSCore

/// Sums `requestedQuantity` per inventory item and rejects non-positive quantities,
/// so a transfer order with two lines for the same item is validated as one total.
private func requestedTotals(for order: TransferOrder) throws -> [UUID: Int] {
    var totals: [UUID: Int] = [:]
    for lineItem in order.lineItems {
        guard lineItem.requestedQuantity > 0 else {
            throw WMSError.validationError("Transfer line items must request a quantity greater than zero.")
        }
        let (sum, overflow) = totals[lineItem.inventoryItemID, default: 0]
            .addingReportingOverflow(lineItem.requestedQuantity)
        guard !overflow else {
            throw WMSError.validationError("Requested quantity is too large.")
        }
        totals[lineItem.inventoryItemID] = sum
    }
    return totals
}

public final class TransferService: Sendable {
    private let transferRepository: any TransferOrderRepository
    private let auditLogger: any AuditLogging
    private let accessController: any PermissionChecking

    public init(
        transferRepository: any TransferOrderRepository,
        auditLogger: any AuditLogging = NullAuditLogger(),
        accessController: any PermissionChecking = NullPermissionChecker()
    ) {
        self.transferRepository = transferRepository
        self.auditLogger = auditLogger
        self.accessController = accessController
    }

    public func getAllTransfers() async throws -> [TransferOrder] {
        try await transferRepository.fetchAll()
    }

    public func getTransfer(byID id: UUID) async throws -> TransferOrder {
        guard let order = try await transferRepository.fetch(byID: id) else {
            throw WMSError.transferNotFound
        }
        return order
    }

    public func createTransfer(
        sourceWarehouseID: UUID,
        destinationWarehouseID: UUID,
        lineItems: [TransferLineItem],
        notes: String
    ) async throws -> TransferOrder {
        try accessController.require(.createTransfer)
        guard sourceWarehouseID != destinationWarehouseID else {
            throw WMSError.validationError("Source and destination warehouses must be different.")
        }
        guard !lineItems.isEmpty else {
            throw WMSError.validationError("Transfer must have at least one line item.")
        }
        for lineItem in lineItems {
            guard lineItem.requestedQuantity > 0 else {
                throw WMSError.validationError("Transfer line items must request a quantity greater than zero.")
            }
        }
        var seen = Set<UUID>()
        for lineItem in lineItems {
            guard seen.insert(lineItem.inventoryItemID).inserted else {
                throw WMSError.validationError("Each inventory item may appear only once per transfer.")
            }
        }

        let code = "TR-\(UUID().uuidString.prefix(8).uppercased())"
        let order = TransferOrder(
            transferCode: code,
            sourceWarehouseID: sourceWarehouseID,
            destinationWarehouseID: destinationWarehouseID,
            notes: notes,
            lineItems: lineItems
        )
        try await transferRepository.save(order)
        await auditLogger.log(entityType: "TransferOrder", entityID: order.id, action: "created")
        return order
    }

    public func submitTransfer(id: UUID) async throws {
        try accessController.require(.submitTransfer)
        try await transferRepository.update(id: id) { order, _ in
            guard order.status == .draft else {
                throw WMSError.invalidTransferState(from: order.status.rawValue, to: "submitted")
            }
            order.status = .submitted
        }
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "submitted")
    }

    public func approveTransfer(id: UUID) async throws {
        try accessController.require(.approveTransfer)
        try await transferRepository.update(id: id) { order, items in
            guard order.status == .submitted else {
                throw WMSError.invalidTransferState(from: order.status.rawValue, to: "approved")
            }
            let totals = try requestedTotals(for: order)
            for (itemID, total) in totals {
                guard let index = items.firstIndex(where: { $0.id == itemID }) else {
                    throw WMSError.inventoryItemNotFound
                }
                let item = items[index]
                guard item.warehouseID == order.sourceWarehouseID else {
                    throw WMSError.validationError(
                        "\(item.name) is not stored in the source warehouse for this transfer."
                    )
                }
                guard item.currentQuantity >= total else {
                    throw WMSError.insufficientStock(
                        itemName: item.name,
                        available: item.currentQuantity,
                        requested: total
                    )
                }
            }
            order.status = .approved
        }
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "approved")
    }

    public func executeTransfer(id: UUID) async throws {
        try accessController.require(.executeTransfer)
        try await transferRepository.update(id: id) { order, items in
            guard order.status == .approved else {
                throw WMSError.invalidTransferState(from: order.status.rawValue, to: "inTransit")
            }
            let totals = try requestedTotals(for: order)
            for (itemID, total) in totals {
                guard let index = items.firstIndex(where: { $0.id == itemID }) else {
                    throw WMSError.inventoryItemNotFound
                }
                let item = items[index]
                guard item.warehouseID == order.sourceWarehouseID else {
                    throw WMSError.validationError(
                        "\(item.name) is not stored in the source warehouse for this transfer."
                    )
                }
                guard item.currentQuantity >= total else {
                    throw WMSError.insufficientStock(
                        itemName: item.name,
                        available: item.currentQuantity,
                        requested: total
                    )
                }
            }
            for (itemID, total) in totals {
                guard let index = items.firstIndex(where: { $0.id == itemID }) else {
                    throw WMSError.inventoryItemNotFound
                }
                items[index].currentQuantity -= total
                items[index].updatedAt = Date()
            }
            for index in order.lineItems.indices {
                order.lineItems[index].transferredQuantity = order.lineItems[index].requestedQuantity
            }
            order.status = .inTransit
        }
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "executed")
    }

    public func completeTransfer(id: UUID) async throws {
        try accessController.require(.completeTransfer)
        try await transferRepository.update(id: id) { order, items in
            guard order.status == .inTransit else {
                throw WMSError.invalidTransferState(from: order.status.rawValue, to: "completed")
            }
            for lineItem in order.lineItems {
                guard lineItem.transferredQuantity > 0 else {
                    throw WMSError.validationError(
                        "Line item for inventory \(lineItem.inventoryItemID) has zero transferred quantity."
                    )
                }
            }
            for lineItem in order.lineItems {
                guard let sourceIndex = items.firstIndex(where: { $0.id == lineItem.inventoryItemID }) else {
                    throw WMSError.inventoryItemNotFound
                }
                let source = items[sourceIndex]
                let alreadyAtDestination = items.firstIndex {
                    $0.id != source.id
                        && $0.warehouseID == order.destinationWarehouseID
                        && $0.sku.caseInsensitiveCompare(source.sku) == .orderedSame
                }
                if let destinationIndex = alreadyAtDestination {
                    let (newQuantity, overflow) = items[destinationIndex].currentQuantity
                        .addingReportingOverflow(lineItem.transferredQuantity)
                    guard !overflow else {
                        throw WMSError.validationError("Quantity would exceed the maximum supported value.")
                    }
                    items[destinationIndex].currentQuantity = newQuantity
                    items[destinationIndex].updatedAt = Date()
                } else {
                    items.append(InventoryItem(
                        sku: source.sku,
                        name: source.name,
                        description: source.description,
                        category: source.category,
                        unitOfMeasure: source.unitOfMeasure,
                        currentQuantity: lineItem.transferredQuantity,
                        minimumThreshold: source.minimumThreshold,
                        unitCost: source.unitCost,
                        warehouseID: order.destinationWarehouseID,
                        isActive: source.isActive
                    ))
                }
            }
            order.status = .completed
            order.completedDate = Date()
        }
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "completed")
    }

    public func cancelTransfer(id: UUID) async throws {
        try accessController.require(.cancelTransfer)
        try await transferRepository.update(id: id) { order, _ in
            switch order.status {
            case .draft, .submitted, .approved:
                order.status = .cancelled
            case .inTransit, .completed, .cancelled:
                throw WMSError.invalidTransferState(from: order.status.rawValue, to: "cancelled")
            }
        }
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "cancelled")
    }
}
