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

        let existing = try await itemRepository.fetch(bySKU: sku, inWarehouseID: warehouseID)
        if existing != nil {
            throw WMSError.duplicateSKU(sku)
        }

        let item = InventoryItem(
            sku: sku.trimmingCharacters(in: .whitespacesAndNewlines),
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
        return item
    }

    public func updateItem(_ item: InventoryItem) async throws {
        try accessController.require(.editInventoryItem)
        try InputValidator.requireNotEmpty(item.sku, field: "SKU")
        var updated = item
        updated.sku = item.sku.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.updatedAt = Date()
        try await itemRepository.save(updated)
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

        var item = try await getItem(byID: itemID)

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
            item.currentQuantity += quantity
        case .adjustment:
            item.currentQuantity = quantity
        }

        item.updatedAt = Date()

        let movement = StockMovement(
            movementType: type,
            quantity: quantity,
            note: note,
            referenceNumber: referenceNumber,
            itemID: itemID,
            warehouseID: item.warehouseID
        )

        try await itemRepository.saveWithMovement(item, movement: movement)
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
