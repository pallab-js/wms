import Foundation

public protocol WarehouseRepository: Sendable {
    func fetchAll() async throws -> [Warehouse]
    func fetchAll(page: Int, pageSize: Int) async throws -> PaginatedResult<Warehouse>
    func fetch(byID id: UUID) async throws -> Warehouse?
    func save(_ warehouse: Warehouse) async throws
    func delete(id: UUID) async throws
}
