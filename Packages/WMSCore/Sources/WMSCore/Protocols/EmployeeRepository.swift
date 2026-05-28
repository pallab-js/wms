import Foundation

public protocol EmployeeRepository: Sendable {
    func fetchAll() async throws -> [Employee]
    func fetchAll(page: Int, pageSize: Int) async throws -> PaginatedResult<Employee>
    func fetch(byID id: UUID) async throws -> Employee?
    func fetch(byWarehouseID warehouseID: UUID) async throws -> [Employee]
    func save(_ employee: Employee) async throws
    func delete(id: UUID) async throws
}
