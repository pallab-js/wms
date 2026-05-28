import Foundation
import WMSCore

public final class FileTransferOrderRepository: TransferOrderRepository {
    private let store: WMSDataStore
    private let file = "transfer_orders.json"

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
        var orders: [TransferOrder] = try store.load([TransferOrder].self, file: file)
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
        } else {
            orders.append(order)
        }
        try store.save(orders, file: file)
    }

    public func delete(id: UUID) async throws {
        var orders: [TransferOrder] = try store.load([TransferOrder].self, file: file)
        orders.removeAll { $0.id == id }
        try store.save(orders, file: file)
    }
}
