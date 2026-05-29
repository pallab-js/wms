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

        let employees = try await employeesTask
        let transfers = try await transfersTask
        let inProgressTransfers = transfers.filter { $0.status == .inTransit || $0.status == .submitted || $0.status == .approved }
        let allItems = try await allItemsTask
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
            itemNames: itemNames
        )
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
        itemNames: [UUID: String]
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
