import Foundation
import WMSCore

public final class FileStockMovementRepository: StockMovementRepository {
    private let store: WMSDataStore
    private let file = "stock_movements.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func fetchAll(forItemID itemID: UUID?) async throws -> [StockMovement] {
        let movements: [StockMovement] = try store.load([StockMovement].self, file: file)
        if let itemID {
            return movements.filter { $0.itemID == itemID }
        }
        return movements
    }

    public func fetchRecent(limit: Int) async throws -> [StockMovement] {
        let movements: [StockMovement] = try store.load([StockMovement].self, file: file)
        return Array(movements.sorted { $0.recordedAt > $1.recordedAt }.prefix(limit))
    }

    public func save(_ movement: StockMovement) async throws {
        var movements: [StockMovement] = try store.load([StockMovement].self, file: file)
        movements.append(movement)
        try store.save(movements, file: file)
    }
}
