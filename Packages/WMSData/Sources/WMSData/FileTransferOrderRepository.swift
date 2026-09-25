import Foundation
import WMSCore

public final class FileTransferOrderRepository: TransferOrderRepository {
    private let store: WMSDataStore
    private let file = "transfer_orders.json"
    private let inventoryFile = "inventory_items.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func fetchAll() async throws -> [TransferOrder] {
        try store.load([TransferOrder].self, file: file)
    }

    public func fetch(byID id: UUID) async throws -> TransferOrder? {
        let orders: [TransferOrder] = try store.load([TransferOrder].self, file: file)
        return orders.first { $0.id == id }
    }

    public func save(_ order: TransferOrder) async throws {
        try store.atomicWrite { store in
            var orders: [TransferOrder] = try store.loadUnsafe([TransferOrder].self, file: self.file)
            if let index = orders.firstIndex(where: { $0.id == order.id }) {
                orders[index] = order
            } else {
                orders.append(order)
            }
            try store.saveUnsafe(orders, file: self.file)
        }
    }

    public func delete(id: UUID) async throws {
        try store.atomicWrite { store in
            var orders: [TransferOrder] = try store.loadUnsafe([TransferOrder].self, file: self.file)
            orders.removeAll { $0.id == id }
            try store.saveUnsafe(orders, file: self.file)
        }
    }

    public func update(
        id: UUID,
        _ mutate: @Sendable (inout TransferOrder, inout [InventoryItem]) throws -> Void
    ) async throws {
        try store.atomicWrite { store in
            var orders: [TransferOrder] = try store.loadUnsafe([TransferOrder].self, file: self.file)
            guard let index = orders.firstIndex(where: { $0.id == id }) else {
                throw WMSError.transferNotFound
            }
            var items: [InventoryItem] = try store.loadUnsafe([InventoryItem].self, file: self.inventoryFile)
            try mutate(&orders[index], &items)
            try store.saveUnsafe(orders, file: self.file)
            try store.saveUnsafe(items, file: self.inventoryFile)
        }
    }
}
