import Foundation

public protocol TransferOrderRepository: Sendable {
    func fetchAll() async throws -> [TransferOrder]
    func fetch(byID id: UUID) async throws -> TransferOrder?
    func save(_ order: TransferOrder) async throws
    func delete(id: UUID) async throws
    func saveWithAtomicItems(_ order: TransferOrder, items: [InventoryItem]) async throws
}
