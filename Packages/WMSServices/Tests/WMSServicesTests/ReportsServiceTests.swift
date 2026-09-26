import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class ReportsServiceTests: XCTestCase {
    private struct Fixture {
        let service: ReportsService
        let warehouseRepo: MockWarehouseRepository
        let itemRepo: MockInventoryItemRepository
        let movementRepo: MockStockMovementRepository
        let transferRepo: MockTransferOrderRepository
        let wh1: UUID
        let wh2: UUID
    }

    private func makeSUT() -> Fixture {
        let warehouseRepo = MockWarehouseRepository()
        let itemRepo = MockInventoryItemRepository()
        let movementRepo = MockStockMovementRepository()
        let transferRepo = MockTransferOrderRepository()
        let alertRepo = MockAlertRepository()

        let wh1 = UUID()
        let wh2 = UUID()
        warehouseRepo.warehouses = [
            Warehouse(id: wh1, name: "Central", code: "WH-001", address: "", capacity: 100),
            Warehouse(id: wh2, name: "North, Main", code: "WH-002", address: "", capacity: 100)
        ]

        itemRepo.items = [
            InventoryItem(sku: "SKU-001", name: "Bolts", category: "Hardware", currentQuantity: 10, minimumThreshold: 2, unitCost: 5.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-002", name: "Tape", category: "Hardware", currentQuantity: 5, minimumThreshold: 1, unitCost: 2.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-003", name: "Wrap", category: " ", currentQuantity: 0, minimumThreshold: 5, unitCost: 3.0, warehouseID: wh1),
            InventoryItem(sku: "SKU-004", name: "Gloves", category: "Safety", currentQuantity: 4, minimumThreshold: 4, unitCost: 10.0, warehouseID: wh2),
            InventoryItem(sku: "SKU-005", name: "Retired", category: "Safety", currentQuantity: 2, minimumThreshold: 10, unitCost: 1.0, warehouseID: wh2, isActive: false),
            InventoryItem(sku: "SKU-006", name: "Bracket", category: "Safety", currentQuantity: 3, minimumThreshold: 0, unitCost: 1.0, warehouseID: wh2)
        ]

        movementRepo.movements = [
            StockMovement(movementType: .stockIn, quantity: 10, itemID: UUID(), warehouseID: wh1),
            StockMovement(movementType: .stockIn, quantity: 5, itemID: UUID(), warehouseID: wh1),
            StockMovement(movementType: .stockOut, quantity: 3, itemID: UUID(), warehouseID: wh2),
            StockMovement(movementType: .adjustment, quantity: 7, itemID: UUID(), warehouseID: wh2)
        ]

        transferRepo.orders = [
            TransferOrder(transferCode: "T-1", status: .draft, sourceWarehouseID: wh1, destinationWarehouseID: wh2),
            TransferOrder(transferCode: "T-2", status: .draft, sourceWarehouseID: wh1, destinationWarehouseID: wh2),
            TransferOrder(transferCode: "T-3", status: .approved, sourceWarehouseID: wh1, destinationWarehouseID: wh2),
            TransferOrder(transferCode: "T-4", status: .completed, sourceWarehouseID: wh2, destinationWarehouseID: wh1)
        ]

        let inventoryService = InventoryService(
            itemRepository: itemRepo,
            movementRepository: movementRepo,
            alertService: InventoryAlertService(alertRepository: alertRepo)
        )
        let movementService = StockMovementService(movementRepository: movementRepo)
        let transferService = TransferService(transferRepository: transferRepo)

        let service = ReportsService(
            warehouseRepository: warehouseRepo,
            inventoryService: inventoryService,
            movementService: movementService,
            transferService: transferService
        )
        return Fixture(
            service: service,
            warehouseRepo: warehouseRepo,
            itemRepo: itemRepo,
            movementRepo: movementRepo,
            transferRepo: transferRepo,
            wh1: wh1,
            wh2: wh2
        )
    }

    func testGetReports_valuationByWarehouse_sortedByValue() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()

        XCTAssertEqual(data.valuationByWarehouse.map(\.warehouseName), ["Central", "North, Main"])
        XCTAssertEqual(data.valuationByWarehouse[0].skuCount, 3)
        XCTAssertEqual(data.valuationByWarehouse[0].unitCount, 15)
        XCTAssertEqual(data.valuationByWarehouse[0].totalValue, 60.0)
        XCTAssertEqual(data.valuationByWarehouse[1].skuCount, 3)
        XCTAssertEqual(data.valuationByWarehouse[1].unitCount, 9)
        XCTAssertEqual(data.valuationByWarehouse[1].totalValue, 45.0)
    }

    func testGetReports_valuationByCategory_groupsEmptyCategory() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()

        XCTAssertEqual(data.valuationByCategory.map(\.category), ["Hardware", "Safety", "Uncategorised"])
        XCTAssertEqual(data.valuationByCategory[0].skuCount, 2)
        XCTAssertEqual(data.valuationByCategory[0].totalValue, 60.0)
        XCTAssertEqual(data.valuationByCategory[2].totalValue, 0.0)
    }

    func testGetReports_movementSummary_countsByType() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()

        XCTAssertEqual(data.movementSummary, [
            MovementSummary(type: .stockIn, count: 2, totalQuantity: 15),
            MovementSummary(type: .stockOut, count: 1, totalQuantity: 3),
            MovementSummary(type: .adjustment, count: 1, totalQuantity: 7)
        ])
    }

    func testGetReports_transferSummary_includesAllStatuses() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()

        XCTAssertEqual(data.transferSummary.map(\.count), [2, 0, 1, 0, 1, 0])
        XCTAssertEqual(data.transferSummary.map(\.label), ["Draft", "Submitted", "Approved", "In Transit", "Completed", "Cancelled"])
    }

    func testGetReports_lowStock_excludesInactiveAndZeroThreshold() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()

        XCTAssertEqual(data.lowStockItems.map(\.sku), ["SKU-003", "SKU-004"])
        XCTAssertEqual(data.warehouseNames[fixture.wh2], "North, Main")
    }

    func testGetReports_repositoryError_throws() async throws {
        let fixture = makeSUT()
        fixture.itemRepo.shouldThrow = true

        do {
            _ = try await fixture.service.getReports()
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .persistenceFailed("Mock error"))
        }
    }

    func testCSV_containsAllSectionsAndHeaders() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()
        let csv = data.csv

        XCTAssertTrue(csv.contains("WarehouseOS Reports,Generated,"))
        XCTAssertTrue(csv.contains("Inventory Valuation by Warehouse"))
        XCTAssertTrue(csv.contains("Warehouse,SKUs,Units,Value"))
        XCTAssertTrue(csv.contains("Valuation by Category"))
        XCTAssertTrue(csv.contains("Stock Movement Activity"))
        XCTAssertTrue(csv.contains("Type,Movements,Total Quantity"))
        XCTAssertTrue(csv.contains("Transfer Orders"))
        XCTAssertTrue(csv.contains("Status,Count"))
        XCTAssertTrue(csv.contains("Low Stock Items"))
        XCTAssertTrue(csv.contains("SKU,Item,Warehouse,Quantity,Threshold,Unit Cost,Value At Risk"))
    }

    func testCSV_escapesCommasAndFormatsMoney() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()
        let csv = data.csv

        XCTAssertTrue(csv.contains("\"North, Main\",3,9,45.00"))
        XCTAssertTrue(csv.contains("Central,3,15,60.00"))
        XCTAssertTrue(csv.contains("SKU-003,Wrap,Central,0,5,3.00,0.00"))
        XCTAssertTrue(csv.hasSuffix("\n"))
    }

    func testCSV_movementAndTransferRows() async throws {
        let fixture = makeSUT()

        let data = try await fixture.service.getReports()
        let csv = data.csv

        XCTAssertTrue(csv.contains("Stock In,2,15"))
        XCTAssertTrue(csv.contains("Stock Out,1,3"))
        XCTAssertTrue(csv.contains("Adjustment,1,7"))
        XCTAssertTrue(csv.contains("Draft,2"))
        XCTAssertTrue(csv.contains("Completed,1"))
    }
}
