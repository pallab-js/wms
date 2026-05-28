import Foundation
import WMSCore

public final class WarehouseService: Sendable {
    private let repository: any WarehouseRepository
    private let auditLogger: any AuditLogging

    public init(
        repository: any WarehouseRepository,
        auditLogger: any AuditLogging = NullAuditLogger()
    ) {
        self.repository = repository
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
        try validateNotEmpty(name, field: "Name")
        try validateNotEmpty(code, field: "Code")
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
        try validateNotEmpty(warehouse.name, field: "Name")
        guard warehouse.capacity > 0 else {
            throw WMSError.validationError("Capacity must be greater than zero.")
        }
        var updated = warehouse
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
        try await repository.delete(id: id)
        await auditLogger.log(entityType: "Warehouse", entityID: id, action: "deleted")
    }

    public func getTotalWarehouseCount() async throws -> Int {
        try await repository.fetchAll().filter(\.isActive).count
    }
}

private extension WarehouseService {
    func validateNotEmpty(_ value: String, field: String) throws {
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WMSError.validationError("\(field) cannot be empty.")
        }
    }
}
