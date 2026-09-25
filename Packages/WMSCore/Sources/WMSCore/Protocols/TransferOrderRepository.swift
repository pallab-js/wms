import Foundation

public protocol TransferOrderRepository: Sendable {
    func fetchAll() async throws -> [TransferOrder]
    func fetch(byID id: UUID) async throws -> TransferOrder?
    func save(_ order: TransferOrder) async throws
    func delete(id: UUID) async throws

    /// Loads the order and the inventory items, applies `mutate` to both, then persists them
    /// inside one critical section. Status transitions and the stock changes they imply are
    /// therefore applied atomically: a second concurrent caller observes the first caller's
    /// result instead of overwriting it.
    func update(
        id: UUID,
        _ mutate: @Sendable (inout TransferOrder, inout [InventoryItem]) throws -> Void
    ) async throws
}
