import Foundation

public protocol InventoryItemRepository: Sendable {
    func fetchAll(forWarehouseID warehouseID: UUID?) async throws -> [InventoryItem]
    /// Paginated fetch. `page` is 0-based; `page`/`pageSize` are clamped to safe values.
    func fetchAll(forWarehouseID warehouseID: UUID?, page: Int, pageSize: Int) async throws -> PaginatedResult<InventoryItem>
    func fetch(byID id: UUID) async throws -> InventoryItem?
    func fetch(bySKU sku: String, inWarehouseID warehouseID: UUID) async throws -> InventoryItem?
    func save(_ item: InventoryItem) async throws
    func saveAll(_ items: [InventoryItem]) async throws
    func delete(id: UUID) async throws

    /// Reads the item, applies `transform`, writes the updated item and appends the movement
    /// returned by `transform` — all inside one critical section so concurrent callers
    /// cannot interleave the read-check-write sequence.
    func applyMovement(
        itemID: UUID,
        _ transform: @Sendable (inout InventoryItem) throws -> StockMovement
    ) async throws -> (InventoryItem, StockMovement)
}
