import Foundation
import WMSCore

public final class DashboardService: Sendable {
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

    public func getDashboardData() async throws -> DashboardData {
        async let warehouseCountTask = warehouseRepository.fetchAll()
        async let skuCountTask = inventoryService.getTotalSKUCount()
        async let totalValueTask = inventoryService.getTotalInventoryValue()
        async let recentMovementsTask = movementService.getRecentMovements(limit: 10)

        let warehouses = try await warehouseCountTask
        let activeWarehouses = warehouses.filter(\.isActive)

        let warehouseSummaries = try await withThrowingTaskGroup(of: WarehouseSummary?.self) { group in
            for warehouse in activeWarehouses {
                group.addTask { [inventoryService] in
                    let items = try await inventoryService.getAllItems(forWarehouseID: warehouse.id)
                    let totalItems = items.reduce(0) { $0 + $1.currentQuantity }
                    let utilisation = warehouse.capacity > 0
                        ? Double(totalItems) / Double(warehouse.capacity) * 100.0
                        : 0.0
                    return WarehouseSummary(
                        warehouse: warehouse,
                        totalItems: totalItems,
                        utilisation: utilisation
                    )
                }
            }

            var summaries: [WarehouseSummary] = []
            for try await summary in group {
                if let summary {
                    summaries.append(summary)
                }
            }
            return summaries
        }

        return DashboardData(
            activeWarehouseCount: activeWarehouses.count,
            totalSKUCount: try await skuCountTask,
            totalInventoryValue: try await totalValueTask,
            warehouseSummaries: warehouseSummaries,
            recentMovements: try await recentMovementsTask
        )
    }
}

public struct DashboardData: Sendable {
    public let activeWarehouseCount: Int
    public let totalSKUCount: Int
    public let totalInventoryValue: Double
    public let warehouseSummaries: [WarehouseSummary]
    public let recentMovements: [StockMovement]

    public init(
        activeWarehouseCount: Int,
        totalSKUCount: Int,
        totalInventoryValue: Double,
        warehouseSummaries: [WarehouseSummary],
        recentMovements: [StockMovement]
    ) {
        self.activeWarehouseCount = activeWarehouseCount
        self.totalSKUCount = totalSKUCount
        self.totalInventoryValue = totalInventoryValue
        self.warehouseSummaries = warehouseSummaries
        self.recentMovements = recentMovements
    }
}

public struct WarehouseSummary: Sendable {
    public let warehouse: Warehouse
    public let totalItems: Int
    public let utilisation: Double

    public init(warehouse: Warehouse, totalItems: Int, utilisation: Double) {
        self.warehouse = warehouse
        self.totalItems = totalItems
        self.utilisation = utilisation
    }
}
