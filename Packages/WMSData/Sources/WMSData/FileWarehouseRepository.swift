import Foundation
import WMSCore

public final class FileWarehouseRepository: WarehouseRepository {
    private let store: WMSDataStore
    private let file = "warehouses.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func fetchAll() async throws -> [Warehouse] {
        try store.load([Warehouse].self, file: file)
    }

    public func fetchAll(page: Int, pageSize: Int) async throws -> PaginatedResult<Warehouse> {
        let all: [Warehouse] = try store.load([Warehouse].self, file: file)
        return Pagination.page(all, page: page, pageSize: pageSize)
    }

    public func fetch(byID id: UUID) async throws -> Warehouse? {
        let warehouses: [Warehouse] = try store.load([Warehouse].self, file: file)
        return warehouses.first { $0.id == id }
    }

    public func save(_ warehouse: Warehouse) async throws {
        try store.atomicWrite { store in
            var warehouses: [Warehouse] = try store.loadUnsafe([Warehouse].self, file: self.file)
            if let index = warehouses.firstIndex(where: { $0.id == warehouse.id }) {
                warehouses[index] = warehouse
            } else {
                warehouses.append(warehouse)
            }
            try store.saveUnsafe(warehouses, file: self.file)
        }
    }

    public func delete(id: UUID) async throws {
        try store.atomicWrite { store in
            var warehouses: [Warehouse] = try store.loadUnsafe([Warehouse].self, file: self.file)
            warehouses.removeAll { $0.id == id }
            try store.saveUnsafe(warehouses, file: self.file)
        }
    }
}
