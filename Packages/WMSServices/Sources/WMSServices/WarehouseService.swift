import Foundation
import WMSCore

public final class WarehouseService: Sendable {
    private let repository: any WarehouseRepository
    private let auditLogger: any AuditLogging
    private let inventoryService: InventoryService?

    public init(
        repository: any WarehouseRepository,
        inventoryService: InventoryService? = nil,
        auditLogger: any AuditLogging = NullAuditLogger()
    ) {
        self.repository = repository
        self.inventoryService = inventoryService
        self.auditLogger = auditLogger
    }

    public func getAllWarehouses() async throws -> [Warehouse] {
        try await repository.fetchAll()
    }

    public func getWarehouse(byID id: UUID) async throws -> Warehouse {
        guard let warehouse = try await repository.fetch(byID: id) else {
            throw WMSError.warehouseNotFound
        }
        return warehouse
    }

    public func createWarehouse(
        name: String,
        code: String,
        address: String,
        capacity: Int
    ) async throws -> Warehouse {
        try InputValidator.requireNotEmpty(name, field: "Name")
        try InputValidator.requireNotEmpty(code, field: "Code")
        guard capacity > 0 else {
            throw WMSError.validationError("Capacity must be greater than zero.")
        }

        let existing = try await repository.fetchAll()
        guard !existing.contains(where: { $0.code.lowercased() == code.lowercased() }) else {
            throw WMSError.duplicateWarehouseCode(code)
        }

        let warehouse = Warehouse(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            code: code.trimmingCharacters(in: .whitespacesAndNewlines),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            capacity: capacity
        )
        try await repository.save(warehouse)
        await auditLogger.log(entityType: "Warehouse", entityID: warehouse.id, action: "created")
        return warehouse
    }

    public func updateWarehouse(_ warehouse: Warehouse) async throws {
        try InputValidator.requireNotEmpty(warehouse.name, field: "Name")
        guard warehouse.capacity > 0 else {
            throw WMSError.validationError("Capacity must be greater than zero.")
        }
        var updated = warehouse
        updated.name = warehouse.name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.code = warehouse.code.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.address = warehouse.address.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.updatedAt = Date()
        try await repository.save(updated)
        await auditLogger.log(entityType: "Warehouse", entityID: warehouse.id, action: "updated")
    }

    public func deactivateWarehouse(id: UUID) async throws {
        var warehouse = try await getWarehouse(byID: id)
        warehouse.isActive = false
        warehouse.updatedAt = Date()
        try await repository.save(warehouse)
        await auditLogger.log(entityType: "Warehouse", entityID: id, action: "deactivated")
    }

    public func deleteWarehouse(id: UUID) async throws {
        let inventoryCount = try await inventoryService?.getItemsCount(forWarehouseID: id) ?? 0
        guard inventoryCount == 0 else {
            throw WMSError.validationError("Cannot delete warehouse with \(inventoryCount) inventory item(s). Remove or reassign items first.")
        }
        try await repository.delete(id: id)
        await auditLogger.log(entityType: "Warehouse", entityID: id, action: "deleted")
    }

    public func getTotalWarehouseCount() async throws -> Int {
        try await repository.fetchAll().filter(\.isActive).count
    }
}
