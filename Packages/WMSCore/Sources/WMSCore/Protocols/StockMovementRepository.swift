import Foundation

public protocol StockMovementRepository: Sendable {
    func fetchAll(forItemID itemID: UUID?) async throws -> [StockMovement]
    func fetchRecent(limit: Int) async throws -> [StockMovement]
    func save(_ movement: StockMovement) async throws
}
