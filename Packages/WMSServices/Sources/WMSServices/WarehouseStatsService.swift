import Foundation
import WMSCore

public final class WarehouseStatsService: Sendable {
    private let warehouseRepository: any WarehouseRepository
    private let inventoryService: InventoryService
    private let movementService: StockMovementService

    public init(
        warehouseRepository: any WarehouseRepository,
        inventoryService: InventoryService,
        movementService: StockMovementService
    ) {
        self.warehouseRepository = warehouseRepository
        self.inventoryService = inventoryService
        self.movementService = movementService
    }

    public func getAllStats() async throws -> [WarehouseStats] {
        async let warehousesTask = warehouseRepository.fetchAll()
        async let itemsTask = inventoryService.getAllItems(forWarehouseID: nil)
        async let movementsTask = movementService.getAllMovements()

        return Self.buildStats(
            warehouses: try await warehousesTask,
            items: try await itemsTask,
            movements: try await movementsTask
        )
    }

    public func getStats(forWarehouseID id: UUID) async throws -> WarehouseStats? {
        try await getAllStats().first { $0.warehouseID == id }
    }

    static func buildStats(
        warehouses: [Warehouse],
        items: [InventoryItem],
        movements: [StockMovement]
    ) -> [WarehouseStats] {
        warehouses.map { warehouse in
            let warehouseItems = items.filter { $0.warehouseID == warehouse.id }
            let warehouseMovements = movements.filter { $0.warehouseID == warehouse.id }
            let unitCount = warehouseItems.reduce(0) { $0 + $1.currentQuantity }
            let totalValue = warehouseItems.reduce(0.0) { $0 + Double($1.currentQuantity) * $1.unitCost }
            let utilisation = warehouse.capacity > 0
                ? Double(unitCount) / Double(warehouse.capacity) * 100.0
                : 0.0
            let lowStockItems = warehouseItems
                .filter { $0.isActive && $0.minimumThreshold > 0 && $0.currentQuantity <= $0.minimumThreshold }
                .sorted { $0.currentQuantity < $1.currentQuantity }

            return WarehouseStats(
                warehouseID: warehouse.id,
                skuCount: warehouseItems.count,
                unitCount: unitCount,
                totalValue: totalValue,
                capacity: warehouse.capacity,
                utilisation: utilisation,
                lowStockItems: lowStockItems,
                categorySummaries: DashboardService.categorySummaries(from: warehouseItems),
                movementTrend: DashboardService.dailyMovementSeries(from: warehouseMovements),
                recentMovements: Array(
                    warehouseMovements
                        .sorted { $0.recordedAt > $1.recordedAt }
                        .prefix(10)
                ),
                itemNames: Dictionary(uniqueKeysWithValues: warehouseItems.map { ($0.id, $0.name) })
            )
        }
    }
}

public struct WarehouseStats: Sendable, Equatable {
    public let warehouseID: UUID
    public let skuCount: Int
    public let unitCount: Int
    public let totalValue: Double
    public let capacity: Int
    public let utilisation: Double
    public let lowStockItems: [InventoryItem]
    public let categorySummaries: [CategorySummary]
    public let movementTrend: [DailyMovement]
    public let recentMovements: [StockMovement]
    public let itemNames: [UUID: String]

    public init(
        warehouseID: UUID,
        skuCount: Int,
        unitCount: Int,
        totalValue: Double,
        capacity: Int,
        utilisation: Double,
        lowStockItems: [InventoryItem],
        categorySummaries: [CategorySummary],
        movementTrend: [DailyMovement],
        recentMovements: [StockMovement],
        itemNames: [UUID: String]
    ) {
        self.warehouseID = warehouseID
        self.skuCount = skuCount
        self.unitCount = unitCount
        self.totalValue = totalValue
        self.capacity = capacity
        self.utilisation = utilisation
        self.lowStockItems = lowStockItems
        self.categorySummaries = categorySummaries
        self.movementTrend = movementTrend
        self.recentMovements = recentMovements
        self.itemNames = itemNames
    }
}
