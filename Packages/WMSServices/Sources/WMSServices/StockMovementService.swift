import Foundation
import WMSCore

public final class StockMovementService: Sendable {
    private let movementRepository: any StockMovementRepository

    public init(movementRepository: any StockMovementRepository) {
        self.movementRepository = movementRepository
    }

    public func getRecentMovements(limit: Int = 10) async throws -> [StockMovement] {
        try await movementRepository.fetchRecent(limit: limit)
    }

    public func getMovements(forItemID itemID: UUID) async throws -> [StockMovement] {
        try await movementRepository.fetchAll(forItemID: itemID)
    }
}
