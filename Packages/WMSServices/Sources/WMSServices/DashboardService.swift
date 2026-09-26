import Foundation
import WMSCore

public final class DashboardService: Sendable {
    private let warehouseRepository: any WarehouseRepository
    private let inventoryService: InventoryService
    private let movementService: StockMovementService
    private let employeeService: EmployeeService
    private let transferService: TransferService
    private let alertService: InventoryAlertService

    public init(
        warehouseRepository: any WarehouseRepository,
        inventoryService: InventoryService,
        movementService: StockMovementService,
        employeeService: EmployeeService,
        transferService: TransferService,
        alertService: InventoryAlertService
    ) {
        self.warehouseRepository = warehouseRepository
        self.inventoryService = inventoryService
        self.movementService = movementService
        self.employeeService = employeeService
        self.transferService = transferService
        self.alertService = alertService
    }

    public func getDashboardData() async throws -> DashboardData {
        async let warehousesTask = warehouseRepository.fetchAll()
        async let skuCountTask = inventoryService.getTotalSKUCount()
        async let totalValueTask = inventoryService.getTotalInventoryValue()
        async let recentMovementsTask = movementService.getRecentMovements(limit: 10)
        async let allMovementsTask = movementService.getAllMovements()
        async let employeesTask = employeeService.getAllEmployees()
        async let transfersTask = transferService.getAllTransfers()
        async let alertsTask = alertService.getUnacknowledgedAlerts()
        async let allItemsTask = inventoryService.getAllItems(forWarehouseID: nil)

        let warehouses = try await warehousesTask
        let activeWarehouses = warehouses.filter(\.isActive)

        let warehouseSummaries = try await withThrowingTaskGroup(of: WarehouseSummary?.self) { group in
            for warehouse in activeWarehouses {
                group.addTask { [inventoryService] in
                    let items = try await inventoryService.getAllItems(forWarehouseID: warehouse.id)
                    let totalItems = items.reduce(0) { $0 + $1.currentQuantity }
                    let totalValue = items.reduce(0.0) { $0 + Double($1.currentQuantity) * $1.unitCost }
                    let utilisation = warehouse.capacity > 0
                        ? Double(totalItems) / Double(warehouse.capacity) * 100.0
                        : 0.0
                    return WarehouseSummary(
                        warehouse: warehouse,
                        totalItems: totalItems,
                        utilisation: utilisation,
                        totalValue: totalValue
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

        let employees = try await employeesTask
        let transfers = try await transfersTask
        let inProgressTransfers = transfers.filter { $0.status == .inTransit || $0.status == .submitted || $0.status == .approved }
        let allItems = try await allItemsTask
        let allMovements = try await allMovementsTask
        let itemNames = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0.name) })

        return DashboardData(
            activeWarehouseCount: activeWarehouses.count,
            totalSKUCount: try await skuCountTask,
            totalInventoryValue: try await totalValueTask,
            warehouseSummaries: warehouseSummaries,
            recentMovements: try await recentMovementsTask,
            employeeCount: employees.filter(\.isActive).count,
            activeTransferCount: inProgressTransfers.count,
            inProgressTransfers: inProgressTransfers,
            lowStockAlerts: try await alertsTask,
            itemNames: itemNames,
            categorySummaries: Self.categorySummaries(from: allItems),
            movementTrend: Self.dailyMovementSeries(from: allMovements)
        )
    }

    static func categorySummaries(from items: [InventoryItem]) -> [CategorySummary] {
        var values: [String: Double] = [:]
        var skus: [String: Int] = [:]
        for item in items {
            let raw = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = raw.isEmpty ? "Uncategorised" : raw
            values[key, default: 0] += Double(item.currentQuantity) * item.unitCost
            skus[key, default: 0] += 1
        }
        return values
            .map { CategorySummary(category: $0.key, skuCount: skus[$0.key, default: 0], totalValue: $0.value) }
            .sorted { $0.totalValue > $1.totalValue }
    }

    static func dailyMovementSeries(
        from movements: [StockMovement],
        now: Date = Date(),
        calendar: Calendar = .current,
        days: Int = 14
    ) -> [DailyMovement] {
        let today = calendar.startOfDay(for: now)
        var buckets: [Date: (stockIn: Int, stockOut: Int)] = [:]
        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            buckets[date] = (0, 0)
        }
        for movement in movements {
            let day = calendar.startOfDay(for: movement.recordedAt)
            guard var entry = buckets[day] else { continue }
            switch movement.movementType {
            case .stockIn: entry.stockIn += movement.quantity
            case .stockOut: entry.stockOut += movement.quantity
            case .adjustment: continue
            }
            buckets[day] = entry
        }
        return buckets
            .sorted { $0.key < $1.key }
            .map { DailyMovement(date: $0.key, stockIn: $0.value.stockIn, stockOut: $0.value.stockOut) }
    }
}

public struct DashboardData: Sendable {
    public let activeWarehouseCount: Int
    public let totalSKUCount: Int
    public let totalInventoryValue: Double
    public let warehouseSummaries: [WarehouseSummary]
    public let recentMovements: [StockMovement]
    public let employeeCount: Int
    public let activeTransferCount: Int
    public let inProgressTransfers: [TransferOrder]
    public let lowStockAlerts: [AlertRecord]
    public let itemNames: [UUID: String]
    public let categorySummaries: [CategorySummary]
    public let movementTrend: [DailyMovement]

    public init(
        activeWarehouseCount: Int,
        totalSKUCount: Int,
        totalInventoryValue: Double,
        warehouseSummaries: [WarehouseSummary],
        recentMovements: [StockMovement],
        employeeCount: Int,
        activeTransferCount: Int,
        inProgressTransfers: [TransferOrder],
        lowStockAlerts: [AlertRecord],
        itemNames: [UUID: String],
        categorySummaries: [CategorySummary],
        movementTrend: [DailyMovement]
    ) {
        self.activeWarehouseCount = activeWarehouseCount
        self.totalSKUCount = totalSKUCount
        self.totalInventoryValue = totalInventoryValue
        self.warehouseSummaries = warehouseSummaries
        self.recentMovements = recentMovements
        self.employeeCount = employeeCount
        self.activeTransferCount = activeTransferCount
        self.inProgressTransfers = inProgressTransfers
        self.lowStockAlerts = lowStockAlerts
        self.itemNames = itemNames
        self.categorySummaries = categorySummaries
        self.movementTrend = movementTrend
    }
}

public struct WarehouseSummary: Sendable {
    public let warehouse: Warehouse
    public let totalItems: Int
    public let utilisation: Double
    public let totalValue: Double

    public init(warehouse: Warehouse, totalItems: Int, utilisation: Double, totalValue: Double) {
        self.warehouse = warehouse
        self.totalItems = totalItems
        self.utilisation = utilisation
        self.totalValue = totalValue
    }
}

public struct CategorySummary: Sendable, Equatable {
    public let category: String
    public let skuCount: Int
    public let totalValue: Double

    public init(category: String, skuCount: Int, totalValue: Double) {
        self.category = category
        self.skuCount = skuCount
        self.totalValue = totalValue
    }
}

public struct DailyMovement: Identifiable, Sendable, Equatable {
    public let date: Date
    public let stockIn: Int
    public let stockOut: Int

    public var id: Date { date }

    public init(date: Date, stockIn: Int, stockOut: Int) {
        self.date = date
        self.stockIn = stockIn
        self.stockOut = stockOut
    }
}
