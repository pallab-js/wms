import Foundation
import WMSCore

public final class TransferService: Sendable {
    private let transferRepository: any TransferOrderRepository
    private let itemRepository: any InventoryItemRepository
    private let auditLogger: any AuditLogging
    private let accessController: any PermissionChecking

    public init(
        transferRepository: any TransferOrderRepository,
        itemRepository: any InventoryItemRepository,
        auditLogger: any AuditLogging = NullAuditLogger(),
        accessController: any PermissionChecking = NullPermissionChecker()
    ) {
        self.transferRepository = transferRepository
        self.itemRepository = itemRepository
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
        var order = try await getTransfer(byID: id)
        guard order.status == .draft else {
            throw WMSError.invalidTransferState(from: order.status.rawValue, to: "submitted")
        }
        order.status = .submitted
        try await transferRepository.save(order)
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "submitted")
    }

    public func approveTransfer(id: UUID) async throws {
        try accessController.require(.approveTransfer)
        var order = try await getTransfer(byID: id)
        guard order.status == .submitted else {
            throw WMSError.invalidTransferState(from: order.status.rawValue, to: "approved")
        }

        for lineItem in order.lineItems {
            let item = try await itemRepository.fetch(byID: lineItem.inventoryItemID)
            guard let item else { throw WMSError.inventoryItemNotFound }
            guard item.currentQuantity >= lineItem.requestedQuantity else {
                throw WMSError.insufficientStock(
                    itemName: item.name,
                    available: item.currentQuantity,
                    requested: lineItem.requestedQuantity
                )
            }
        }

        order.status = .approved
        try await transferRepository.save(order)
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "approved")
    }

    public func executeTransfer(id: UUID) async throws {
        try accessController.require(.executeTransfer)
        var order = try await getTransfer(byID: id)
        guard order.status == .approved else {
            throw WMSError.invalidTransferState(from: order.status.rawValue, to: "inTransit")
        }

        var updatedItems: [InventoryItem] = []
        for i in 0..<order.lineItems.count {
            let lineItem = order.lineItems[i]
            guard var item = try await itemRepository.fetch(byID: lineItem.inventoryItemID) else {
                throw WMSError.inventoryItemNotFound
            }
            guard item.currentQuantity >= lineItem.requestedQuantity else {
                throw WMSError.insufficientStock(
                    itemName: item.name,
                    available: item.currentQuantity,
                    requested: lineItem.requestedQuantity
                )
            }
            item.currentQuantity -= lineItem.requestedQuantity
            item.updatedAt = Date()
            item.warehouseID = order.destinationWarehouseID
            updatedItems.append(item)
            order.lineItems[i].transferredQuantity = lineItem.requestedQuantity
        }

        order.status = .inTransit
        try await transferRepository.saveWithAtomicItems(order, items: updatedItems)
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "executed")
    }

    public func completeTransfer(id: UUID) async throws {
        try accessController.require(.completeTransfer)
        var order = try await getTransfer(byID: id)
        guard order.status == .inTransit else {
            throw WMSError.invalidTransferState(from: order.status.rawValue, to: "completed")
        }

        var updatedItems: [InventoryItem] = []
        for lineItem in order.lineItems {
            guard lineItem.transferredQuantity > 0 else {
                throw WMSError.validationError(
                    "Line item for inventory \(lineItem.inventoryItemID) has zero transferred quantity."
                )
            }
            guard var item = try await itemRepository.fetch(byID: lineItem.inventoryItemID) else {
                throw WMSError.inventoryItemNotFound
            }
            item.updatedAt = Date()
            updatedItems.append(item)
        }

        order.status = .completed
        order.completedDate = Date()
        try await transferRepository.saveWithAtomicItems(order, items: updatedItems)
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "completed")
    }

    public func cancelTransfer(id: UUID) async throws {
        try accessController.require(.cancelTransfer)
        var order = try await getTransfer(byID: id)
        guard order.status == .submitted || order.status == .approved else {
            throw WMSError.invalidTransferState(from: order.status.rawValue, to: "cancelled")
        }
        order.status = .cancelled
        try await transferRepository.save(order)
        await auditLogger.log(entityType: "TransferOrder", entityID: id, action: "cancelled")
    }
}
