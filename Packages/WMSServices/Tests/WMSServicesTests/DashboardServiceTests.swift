import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class DashboardServiceTests: XCTestCase {
    private struct Fixture {
        let service: DashboardService
        let warehouseRepo: MockWarehouseRepository
        let itemRepo: MockInventoryItemRepository
        let movementRepo: MockStockMovementRepository
        let transferRepo: MockTransferOrderRepository
        let employeeRepo: MockEmployeeRepository
        let alertRepo: MockAlertRepository
        let wh1: UUID
        let wh2: UUID
    }

    private func makeSUT() -> Fixture {
        let warehouseRepo = MockWarehouseRepository()
        let itemRepo = MockInventoryItemRepository()
        let movementRepo = MockStockMovementRepository()
        let transferRepo = MockTransferOrderRepository()
        let employeeRepo = MockEmployeeRepository()
        let alertRepo = MockAlertRepository()

        let wh1 = UUID()
        let wh2 = UUID()
        warehouseRepo.warehouses = [
            Warehouse(id: wh1, name: "Central", code: "WH-001", address: "", capacity: 100),
            Warehouse(id: wh2, name: "North", code: "WH-002", address: "", capacity: 200)
        ]
        itemRepo.items = [
            InventoryItem(sku: "SKU-001", name: "Bolts", category: "Hardware", currentQuantity: 10, unitCost: 5.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-002", name: "Tape", category: "Hardware", currentQuantity: 5, unitCost: 2.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-003", name: "Gloves", category: "Safety", currentQuantity: 40, unitCost: 10.0, warehouseID: wh2),
            InventoryItem(sku: "SKU-004", name: "Wrap", category: "", currentQuantity: 0, unitCost: 3.0, warehouseID: wh2)
        ]

        let alertService = InventoryAlertService(alertRepository: alertRepo)
        let inventoryService = InventoryService(
            itemRepository: itemRepo,
            movementRepository: movementRepo,
            alertService: alertService
        )
        let movementService = StockMovementService(movementRepository: movementRepo)
        let employeeService = EmployeeService(repository: employeeRepo)
        let transferService = TransferService(transferRepository: transferRepo)

        let service = DashboardService(
            warehouseRepository: warehouseRepo,
            inventoryService: inventoryService,
            movementService: movementService,
            employeeService: employeeService,
            transferService: transferService,
            alertService: alertService
        )
        return Fixture(
            service: service,
            warehouseRepo: warehouseRepo,
            itemRepo: itemRepo,
            movementRepo: movementRepo,
            transferRepo: transferRepo,
            employeeRepo: employeeRepo,
            alertRepo: alertRepo,
            wh1: wh1,
            wh2: wh2
        )
    }

    func testGetDashboardData_warehouseSummaries_includeTotalValue() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getDashboardData()

        XCTAssertEqual(data.warehouseSummaries.count, 2)
        let central = data.warehouseSummaries.first { $0.warehouse.id == fixture.wh1 }
        XCTAssertEqual(central?.totalItems, 15)
        XCTAssertEqual(central?.totalValue, 60.0)
        XCTAssertEqual(central?.utilisation, 15.0)
        let north = data.warehouseSummaries.first { $0.warehouse.id == fixture.wh2 }
        XCTAssertEqual(north?.totalItems, 40)
        XCTAssertEqual(north?.totalValue, 400.0)
        XCTAssertEqual(north?.utilisation, 20.0)
    }

    func testGetDashboardData_includesCategorySummariesAndMovementTrend() async throws {
        let fixture = makeSUT()
        let today = Calendar.current.startOfDay(for: Date())
        fixture.movementRepo.movements = [
            StockMovement(movementType: .stockIn, quantity: 12, recordedAt: today, itemID: UUID(), warehouseID: fixture.wh1),
            StockMovement(movementType: .stockOut, quantity: 3, recordedAt: today, itemID: UUID(), warehouseID: fixture.wh1)
        ]

        let data = try await fixture.service.getDashboardData()

        XCTAssertEqual(data.categorySummaries.map(\.category), ["Safety", "Hardware", "Uncategorised"])
        XCTAssertEqual(data.categorySummaries[0].totalValue, 400.0)
        XCTAssertEqual(data.categorySummaries[1].skuCount, 2)
        XCTAssertEqual(data.movementTrend.count, 14)
        XCTAssertEqual(data.movementTrend.last?.date, today)
        XCTAssertEqual(data.movementTrend.last?.stockIn, 12)
        XCTAssertEqual(data.movementTrend.last?.stockOut, 3)
    }

    func testCategorySummaries_emptyCategoryBecomesUncategorised() {
        let items = [
            InventoryItem(sku: "A", name: "A", category: "  ", currentQuantity: 2, unitCost: 5.0, warehouseID: UUID()),
            InventoryItem(sku: "B", name: "B", category: "Parts", currentQuantity: 1, unitCost: 1.0, warehouseID: UUID())
        ]

        let summaries = DashboardService.categorySummaries(from: items)

        XCTAssertEqual(summaries.map(\.category), ["Uncategorised", "Parts"])
        XCTAssertEqual(summaries[0].totalValue, 10.0)
        XCTAssertEqual(summaries[1].totalValue, 1.0)
    }

    func testDailyMovementSeries_zeroFilledAndSortedAscending() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 26))!
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: now)!
        let movements = [
            StockMovement(movementType: .stockIn, quantity: 5, recordedAt: threeDaysAgo, itemID: UUID(), warehouseID: UUID()),
            StockMovement(movementType: .stockIn, quantity: 7, recordedAt: threeDaysAgo, itemID: UUID(), warehouseID: UUID()),
            StockMovement(movementType: .stockOut, quantity: 2, recordedAt: threeDaysAgo, itemID: UUID(), warehouseID: UUID())
        ]

        let series = DashboardService.dailyMovementSeries(from: movements, now: now, calendar: calendar, days: 14)

        XCTAssertEqual(series.count, 14)
        XCTAssertEqual(series.first?.date, calendar.date(byAdding: .day, value: -13, to: now))
        XCTAssertEqual(series.last?.date, now)
        let bucket = series.first { $0.date == threeDaysAgo }
        XCTAssertEqual(bucket?.stockIn, 12)
        XCTAssertEqual(bucket?.stockOut, 2)
        for day in series where day.date != threeDaysAgo {
            XCTAssertEqual(day.stockIn, 0)
            XCTAssertEqual(day.stockOut, 0)
        }
    }

    func testDailyMovementSeries_excludesAdjustmentsAndOldMovements() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 26))!
        let twentyDaysAgo = calendar.date(byAdding: .day, value: -20, to: now)!
        let movements = [
            StockMovement(movementType: .adjustment, quantity: 99, recordedAt: now, itemID: UUID(), warehouseID: UUID()),
            StockMovement(movementType: .stockIn, quantity: 4, recordedAt: twentyDaysAgo, itemID: UUID(), warehouseID: UUID())
        ]

        let series = DashboardService.dailyMovementSeries(from: movements, now: now, calendar: calendar, days: 14)

        XCTAssertTrue(series.allSatisfy { $0.stockIn == 0 && $0.stockOut == 0 })
    }

    func testDailyMovementSeries_emptyMovements_returnsAllZeroDays() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 26))!

        let series = DashboardService.dailyMovementSeries(from: [], now: now, calendar: calendar, days: 14)

        XCTAssertEqual(series.count, 14)
        XCTAssertTrue(series.allSatisfy { $0.stockIn == 0 && $0.stockOut == 0 })
    }
}
