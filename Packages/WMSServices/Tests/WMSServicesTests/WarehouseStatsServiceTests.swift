import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class WarehouseStatsServiceTests: XCTestCase {
    private struct Fixture {
        let service: WarehouseStatsService
        let warehouseRepo: MockWarehouseRepository
        let itemRepo: MockInventoryItemRepository
        let movementRepo: MockStockMovementRepository
        let wh1: UUID
        let wh2: UUID
    }

    private func makeSUT() -> Fixture {
        let warehouseRepo = MockWarehouseRepository()
        let itemRepo = MockInventoryItemRepository()
        let movementRepo = MockStockMovementRepository()

        let wh1 = UUID()
        let wh2 = UUID()
        warehouseRepo.warehouses = [
            Warehouse(id: wh1, name: "Central", code: "WH-001", address: "", capacity: 100),
            Warehouse(id: wh2, name: "North", code: "WH-002", address: "", capacity: 200)
        ]
        itemRepo.items = [
            InventoryItem(sku: "SKU-001", name: "Bolts", category: "Hardware", currentQuantity: 30, minimumThreshold: 5, unitCost: 2.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-002", name: "Tape", category: "Packaging", currentQuantity: 10, minimumThreshold: 40, unitCost: 3.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-003", name: "Gloves", category: "Safety", currentQuantity: 120, minimumThreshold: 10, unitCost: 5.0, warehouseID: wh2)
        ]
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        movementRepo.movements = [
            StockMovement(movementType: .stockIn, quantity: 5, recordedAt: yesterday, itemID: itemRepo.items[0].id, warehouseID: wh1),
            StockMovement(movementType: .stockOut, quantity: 2, recordedAt: today, itemID: itemRepo.items[0].id, warehouseID: wh1),
            StockMovement(movementType: .stockIn, quantity: 50, recordedAt: today, itemID: itemRepo.items[2].id, warehouseID: wh2)
        ]

        let inventoryService = InventoryService(
            itemRepository: itemRepo,
            movementRepository: movementRepo,
            alertService: InventoryAlertService(alertRepository: MockAlertRepository())
        )
        let service = WarehouseStatsService(
            warehouseRepository: warehouseRepo,
            inventoryService: inventoryService,
            movementService: StockMovementService(movementRepository: movementRepo)
        )
        return Fixture(
            service: service,
            warehouseRepo: warehouseRepo,
            itemRepo: itemRepo,
            movementRepo: movementRepo,
            wh1: wh1,
            wh2: wh2
        )
    }

    func testGetAllStats_countsValueAndUtilisationPerWarehouse() async throws {
        let fixture = makeSUT()

        let stats = try await fixture.service.getAllStats()

        XCTAssertEqual(stats.count, 2)
        let central = stats.first { $0.warehouseID == fixture.wh1 }
        XCTAssertEqual(central?.skuCount, 2)
        XCTAssertEqual(central?.unitCount, 40)
        XCTAssertEqual(central?.totalValue, 90.0)
        XCTAssertEqual(central?.utilisation, 40.0)
        let north = stats.first { $0.warehouseID == fixture.wh2 }
        XCTAssertEqual(north?.skuCount, 1)
        XCTAssertEqual(north?.unitCount, 120)
        XCTAssertEqual(north?.totalValue, 600.0)
        XCTAssertEqual(north?.utilisation, 60.0)
    }

    func testGetAllStats_scopesLowStockToWarehouse() async throws {
        let fixture = makeSUT()

        let stats = try await fixture.service.getAllStats()

        let central = stats.first { $0.warehouseID == fixture.wh1 }
        XCTAssertEqual(central?.lowStockItems.map(\.sku), ["SKU-002"])
        let north = stats.first { $0.warehouseID == fixture.wh2 }
        XCTAssertTrue(north?.lowStockItems.isEmpty ?? false)
    }

    func testGetAllStats_scopesMovementsAndTrendToWarehouse() async throws {
        let fixture = makeSUT()

        let stats = try await fixture.service.getAllStats()

        let central = stats.first { $0.warehouseID == fixture.wh1 }
        XCTAssertEqual(central?.recentMovements.count, 2)
        XCTAssertEqual(central?.recentMovements.first?.movementType, .stockOut)
        XCTAssertEqual(central?.movementTrend.count, 14)
        XCTAssertEqual(central?.movementTrend.last?.stockIn, 0)
        XCTAssertEqual(central?.movementTrend.last?.stockOut, 2)
        let north = stats.first { $0.warehouseID == fixture.wh2 }
        XCTAssertEqual(north?.recentMovements.count, 1)
        XCTAssertEqual(north?.movementTrend.last?.stockIn, 50)
    }

    func testGetAllStats_recentMovementsSortedDescendingAndCapped() async throws {
        let fixture = makeSUT()
        let now = Date()
        for index in 0..<15 {
            fixture.movementRepo.movements.append(
                StockMovement(
                    movementType: .stockIn,
                    quantity: index,
                    recordedAt: now.addingTimeInterval(Double(index)),
                    itemID: UUID(),
                    warehouseID: fixture.wh1
                )
            )
        }

        let stats = try await fixture.service.getAllStats()
        let central = stats.first { $0.warehouseID == fixture.wh1 }

        XCTAssertEqual(central?.recentMovements.count, 10)
        XCTAssertEqual(central?.recentMovements.first?.quantity, 14)
        XCTAssertEqual(central?.recentMovements.last?.quantity, 5)
    }

    func testGetAllStats_categorySummariesScopedToWarehouse() async throws {
        let fixture = makeSUT()

        let stats = try await fixture.service.getAllStats()

        let central = stats.first { $0.warehouseID == fixture.wh1 }
        XCTAssertEqual(central?.categorySummaries.map(\.category), ["Hardware", "Packaging"])
        XCTAssertEqual(central?.categorySummaries.first?.totalValue, 60.0)
    }

    func testGetStats_returnsMatchingWarehouseOrNil() async throws {
        let fixture = makeSUT()

        let stats = try await fixture.service.getStats(forWarehouseID: fixture.wh2)

        XCTAssertEqual(stats?.warehouseID, fixture.wh2)
        let missing = try await fixture.service.getStats(forWarehouseID: UUID())
        XCTAssertNil(missing)
    }

    func testBuildStats_emptyWarehouse_returnsZeros() {
        let warehouse = Warehouse(name: "Empty", code: "WH-E", address: "", capacity: 50)

        let stats = WarehouseStatsService.buildStats(warehouses: [warehouse], items: [], movements: [])

        XCTAssertEqual(stats.count, 1)
        XCTAssertEqual(stats[0].skuCount, 0)
        XCTAssertEqual(stats[0].unitCount, 0)
        XCTAssertEqual(stats[0].totalValue, 0)
        XCTAssertEqual(stats[0].utilisation, 0)
        XCTAssertTrue(stats[0].lowStockItems.isEmpty)
        XCTAssertEqual(stats[0].movementTrend.count, 14)
    }
}
