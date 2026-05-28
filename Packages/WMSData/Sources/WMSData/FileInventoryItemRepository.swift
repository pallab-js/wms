import Foundation
import WMSCore

public final class FileInventoryItemRepository: InventoryItemRepository {
    private let store: WMSDataStore
    private let file = "inventory_items.json"
    private let movementFile = "stock_movements.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func fetchAll(forWarehouseID warehouseID: UUID?) async throws -> [InventoryItem] {
        let items: [InventoryItem] = try store.load([InventoryItem].self, file: file)
        if let warehouseID {
            return items.filter { $0.warehouseID == warehouseID }
        }
        return items
    }

    public func fetchAll(forWarehouseID warehouseID: UUID?, page: Int, pageSize: Int) async throws -> PaginatedResult<InventoryItem> {
        let all: [InventoryItem] = try store.load([InventoryItem].self, file: file)
        let filtered = if let warehouseID {
            all.filter { $0.warehouseID == warehouseID }
        } else {
            all
        }
        let start = page * pageSize
        let end = min(start + pageSize, filtered.count)
        let items = start < filtered.count ? Array(filtered[start..<end]) : []
        return PaginatedResult(items: items, totalCount: filtered.count, page: page, pageSize: pageSize)
    }

    public func fetch(byID id: UUID) async throws -> InventoryItem? {
        let items: [InventoryItem] = try store.load([InventoryItem].self, file: file)
        return items.first { $0.id == id }
    }

    public func fetch(bySKU sku: String, inWarehouseID warehouseID: UUID) async throws -> InventoryItem? {
        let items: [InventoryItem] = try store.load([InventoryItem].self, file: file)
        return items.first { $0.sku == sku && $0.warehouseID == warehouseID }
    }

    public func save(_ item: InventoryItem) async throws {
        var items: [InventoryItem] = try store.load([InventoryItem].self, file: file)
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
        try store.save(items, file: file)
    }

    public func saveWithMovement(_ item: InventoryItem, movement: StockMovement) async throws {
        try store.atomicWrite {
            var items: [InventoryItem] = try self.store.load([InventoryItem].self, file: self.file)
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
            } else {
                items.append(item)
            }
            try self.store.save(items, file: self.file)

            var movements: [StockMovement] = try self.store.load([StockMovement].self, file: self.movementFile)
            movements.append(movement)
            try self.store.save(movements, file: self.movementFile)
        }
    }

    public func delete(id: UUID) async throws {
        var items: [InventoryItem] = try store.load([InventoryItem].self, file: file)
        items.removeAll { $0.id == id }
        try store.save(items, file: file)
    }
}
