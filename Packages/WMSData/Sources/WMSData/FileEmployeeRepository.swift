import Foundation
import WMSCore

public final class FileEmployeeRepository: EmployeeRepository {
    private let store: WMSDataStore
    private let file = "employees.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func fetchAll() async throws -> [Employee] {
        try store.load([Employee].self, file: file)
    }

    public func fetchAll(page: Int, pageSize: Int) async throws -> PaginatedResult<Employee> {
        let all: [Employee] = try store.load([Employee].self, file: file)
        return Pagination.page(all, page: page, pageSize: pageSize)
    }

    public func fetch(byID id: UUID) async throws -> Employee? {
        let employees: [Employee] = try store.load([Employee].self, file: file)
        return employees.first { $0.id == id }
    }

    public func fetch(byWarehouseID warehouseID: UUID) async throws -> [Employee] {
        let employees: [Employee] = try store.load([Employee].self, file: file)
        return employees.filter { $0.warehouseIDs.contains(warehouseID) }
    }

    public func save(_ employee: Employee) async throws {
        try store.atomicWrite { store in
            var employees: [Employee] = try store.loadUnsafe([Employee].self, file: self.file)
            if let index = employees.firstIndex(where: { $0.id == employee.id }) {
                employees[index] = employee
            } else {
                employees.append(employee)
            }
            try store.saveUnsafe(employees, file: self.file)
        }
    }

    public func delete(id: UUID) async throws {
        try store.atomicWrite { store in
            var employees: [Employee] = try store.loadUnsafe([Employee].self, file: self.file)
            employees.removeAll { $0.id == id }
            try store.saveUnsafe(employees, file: self.file)
        }
    }
}
