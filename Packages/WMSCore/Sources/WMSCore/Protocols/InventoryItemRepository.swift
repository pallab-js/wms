import Foundation

public protocol InventoryItemRepository: Sendable {
    func fetchAll(forWarehouseID warehouseID: UUID?) async throws -> [InventoryItem]
    func fetchAll(forWarehouseID warehouseID: UUID?, page: Int, pageSize: Int) async throws -> PaginatedResult<InventoryItem>
    func fetch(byID id: UUID) async throws -> InventoryItem?
    func fetch(bySKU sku: String, inWarehouseID warehouseID: UUID) async throws -> InventoryItem?
    func save(_ item: InventoryItem) async throws
    func saveAll(_ items: [InventoryItem]) async throws
    func saveWithMovement(_ item: InventoryItem, movement: StockMovement) async throws
    func delete(id: UUID) async throws
}
