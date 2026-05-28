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
        let start = page * pageSize
        let end = min(start + pageSize, all.count)
        let items = start < all.count ? Array(all[start..<end]) : []
        return PaginatedResult(items: items, totalCount: all.count, page: page, pageSize: pageSize)
    }

    public func fetch(byID id: UUID) async throws -> Warehouse? {
        let warehouses: [Warehouse] = try store.load([Warehouse].self, file: file)
        return warehouses.first { $0.id == id }
    }

    public func save(_ warehouse: Warehouse) async throws {
        var warehouses: [Warehouse] = try store.load([Warehouse].self, file: file)
        if let index = warehouses.firstIndex(where: { $0.id == warehouse.id }) {
            warehouses[index] = warehouse
        } else {
            warehouses.append(warehouse)
        }
        try store.save(warehouses, file: file)
    }

    public func delete(id: UUID) async throws {
        var warehouses: [Warehouse] = try store.load([Warehouse].self, file: file)
        warehouses.removeAll { $0.id == id }
        try store.save(warehouses, file: file)
    }
}
