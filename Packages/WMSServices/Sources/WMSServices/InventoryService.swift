import Foundation
import WMSCore

public final class InventoryService: Sendable {
    private let itemRepository: any InventoryItemRepository
    private let movementRepository: any StockMovementRepository
    private let alertService: InventoryAlertService
    private let auditLogger: any AuditLogging
    private let accessController: any PermissionChecking

    public init(
        itemRepository: any InventoryItemRepository,
        movementRepository: any StockMovementRepository,
        alertService: InventoryAlertService,
        auditLogger: any AuditLogging = NullAuditLogger(),
        accessController: any PermissionChecking = NullPermissionChecker()
    ) {
        self.itemRepository = itemRepository
        self.movementRepository = movementRepository
        self.alertService = alertService
        self.auditLogger = auditLogger
        self.accessController = accessController
    }

    public func getAllItems(forWarehouseID warehouseID: UUID? = nil) async throws -> [InventoryItem] {
        try await itemRepository.fetchAll(forWarehouseID: warehouseID)
    }

    public func getItemsCount(forWarehouseID warehouseID: UUID) async throws -> Int {
        try await itemRepository.fetchAll(forWarehouseID: warehouseID).count
    }

    public func getItem(byID id: UUID) async throws -> InventoryItem {
        guard let item = try await itemRepository.fetch(byID: id) else {
            throw WMSError.inventoryItemNotFound
        }
        return item
    }

    public func createItem(
        sku: String,
        name: String,
        description: String,
        category: String,
        unitOfMeasure: String,
        currentQuantity: Int,
        minimumThreshold: Int,
        unitCost: Double,
        warehouseID: UUID
    ) async throws -> InventoryItem {
        try accessController.require(.recordStockIn)
        try InputValidator.requireNotEmpty(sku, field: "SKU")
        try InputValidator.requireNotEmpty(name, field: "Name")
        try InputValidator.requireNonNegativeInt(currentQuantity, field: "Quantity")
        try InputValidator.requireNonNegativeInt(minimumThreshold, field: "Threshold")
        try InputValidator.requireNonNegativeDouble(unitCost, field: "Unit cost")

        let trimmedSKU = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = try await itemRepository.fetch(bySKU: trimmedSKU, inWarehouseID: warehouseID)
        if existing != nil {
            throw WMSError.duplicateSKU(trimmedSKU)
        }

        let item = InventoryItem(
            sku: trimmedSKU,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description,
            category: category,
            unitOfMeasure: unitOfMeasure,
            currentQuantity: currentQuantity,
            minimumThreshold: minimumThreshold,
            unitCost: unitCost,
            warehouseID: warehouseID
        )
        try await itemRepository.save(item)
        await auditLogger.log(entityType: "InventoryItem", entityID: item.id, action: "created")
        await alertService.checkThresholds(for: item)
        return item
    }

    public func updateItem(_ item: InventoryItem) async throws {
        try accessController.require(.editInventoryItem)
        try InputValidator.requireNotEmpty(item.sku, field: "SKU")
        try InputValidator.requireNotEmpty(item.name, field: "Name")
        try InputValidator.requireNonNegativeInt(item.currentQuantity, field: "Quantity")
        try InputValidator.requireNonNegativeInt(item.minimumThreshold, field: "Threshold")
        try InputValidator.requireNonNegativeDouble(item.unitCost, field: "Unit cost")

        let trimmedSKU = item.sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let existing = try await getItem(byID: item.id)
        if let duplicate = try await itemRepository.fetch(bySKU: trimmedSKU, inWarehouseID: existing.warehouseID),
           duplicate.id != item.id {
            throw WMSError.duplicateSKU(trimmedSKU)
        }

        var updated = item
        updated.sku = trimmedSKU
        updated.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.updatedAt = Date()

        if updated.currentQuantity == existing.currentQuantity {
            updated.warehouseID = existing.warehouseID
            try await itemRepository.save(updated)
        } else {
            let movement = StockMovement(
                movementType: .adjustment,
                quantity: updated.currentQuantity,
                note: "Quantity edited on inventory item",
                referenceNumber: nil,
                itemID: item.id,
                warehouseID: existing.warehouseID
            )
            let target = updated
            let (applied, _) = try await itemRepository.applyMovement(itemID: item.id) { stored in
                stored.sku = target.sku
                stored.name = target.name
                stored.description = target.description
                stored.category = target.category
                stored.unitOfMeasure = target.unitOfMeasure
                stored.minimumThreshold = target.minimumThreshold
                stored.unitCost = target.unitCost
                stored.isActive = target.isActive
                stored.currentQuantity = target.currentQuantity
                stored.updatedAt = target.updatedAt
                return movement
            }
            updated = applied
            await alertService.checkThresholds(for: updated)
        }
        await auditLogger.log(entityType: "InventoryItem", entityID: item.id, action: "updated")
    }

    public func deleteItem(id: UUID) async throws {
        try accessController.require(.deleteInventoryItem)
        try await itemRepository.delete(id: id)
        await auditLogger.log(entityType: "InventoryItem", entityID: id, action: "deleted")
    }

    public func recordMovement(
        itemID: UUID,
        type: MovementType,
        quantity: Int,
        note: String?,
        referenceNumber: String?
    ) async throws -> StockMovement {
        let permission: Permission = switch type {
        case .stockIn: .recordStockIn
        case .stockOut: .recordStockOut
        case .adjustment: .adjustStock
        }
        try accessController.require(permission)

        guard quantity > 0 else {
            throw WMSError.validationError("Quantity must be greater than zero.")
        }

        let (item, movement) = try await itemRepository.applyMovement(itemID: itemID) { item in
            switch type {
            case .stockOut:
                guard item.currentQuantity >= quantity else {
                    throw WMSError.insufficientStock(
                        itemName: item.name,
                        available: item.currentQuantity,
                        requested: quantity
                    )
                }
                item.currentQuantity -= quantity
            case .stockIn:
                let (newValue, overflow) = item.currentQuantity.addingReportingOverflow(quantity)
                guard !overflow else {
                    throw WMSError.validationError("Quantity would exceed the maximum supported value.")
                }
                item.currentQuantity = newValue
            case .adjustment:
                item.currentQuantity = quantity
            }
            item.updatedAt = Date()
            return StockMovement(
                movementType: type,
                quantity: quantity,
                note: note,
                referenceNumber: referenceNumber,
                itemID: itemID,
                warehouseID: item.warehouseID
            )
        }

        await auditLogger.log(entityType: "StockMovement", entityID: movement.id, action: "recorded")
        await alertService.checkThresholds(for: item)

        return movement
    }

    public func getMovements(forItemID itemID: UUID?) async throws -> [StockMovement] {
        try await movementRepository.fetchAll(forItemID: itemID)
    }

    public func getRecentMovements(limit: Int = 10) async throws -> [StockMovement] {
        try await movementRepository.fetchRecent(limit: limit)
    }

    public func getTotalSKUCount() async throws -> Int {
        try await itemRepository.fetchAll(forWarehouseID: nil).count
    }

    public func getTotalInventoryValue() async throws -> Double {
        let items = try await itemRepository.fetchAll(forWarehouseID: nil)
        return items.reduce(0.0) { $0 + (Double($1.currentQuantity) * $1.unitCost) }
    }
}
