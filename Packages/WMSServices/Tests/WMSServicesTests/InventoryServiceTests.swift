import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class InventoryServiceTests: XCTestCase {
    private func makeSUT() -> (InventoryService, MockInventoryItemRepository, MockStockMovementRepository) {
        let itemRepo = MockInventoryItemRepository()
        let movementRepo = MockStockMovementRepository()
        let alertRepo = MockAlertRepository()
        let auditRepo = MockAuditRepository()
        let alertService = InventoryAlertService(alertRepository: alertRepo)
        let auditLogger = AuditLogger(repository: auditRepo)
        let service = InventoryService(
            itemRepository: itemRepo,
            movementRepository: movementRepo,
            alertService: alertService,
            auditLogger: auditLogger
        )
        return (service, itemRepo, movementRepo)
    }

    func testCreateItem_validInput_succeeds() async throws {
        let (service, repo, _) = makeSUT()
        let warehouseID = UUID()

        let item = try await service.createItem(
            sku: "SKU-001",
            name: "Widget",
            description: "A test widget",
            category: "Parts",
            unitOfMeasure: "units",
            currentQuantity: 50,
            minimumThreshold: 10,
            unitCost: 9.99,
            warehouseID: warehouseID
        )

        XCTAssertEqual(item.sku, "SKU-001")
        XCTAssertEqual(item.name, "Widget")
        XCTAssertEqual(item.currentQuantity, 50)
        XCTAssertEqual(repo.items.count, 1)
    }

    func testCreateItem_duplicateSKU_throws() async throws {
        let (service, repo, _) = makeSUT()
        let warehouseID = UUID()
        repo.items = [InventoryItem(sku: "SKU-001", name: "Existing", warehouseID: warehouseID)]

        do {
            _ = try await service.createItem(
                sku: "SKU-001", name: "New", description: "", category: "",
                unitOfMeasure: "units", currentQuantity: 0, minimumThreshold: 0,
                unitCost: 0, warehouseID: warehouseID
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .duplicateSKU("SKU-001"))
        }
    }

    func testCreateItem_emptySKU_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.createItem(
                sku: "", name: "Widget", description: "", category: "",
                unitOfMeasure: "units", currentQuantity: 0, minimumThreshold: 0,
                unitCost: 0, warehouseID: UUID()
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("SKU cannot be empty."))
        }
    }

    func testCreateItem_emptyName_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.createItem(
                sku: "SKU-001", name: "", description: "", category: "",
                unitOfMeasure: "units", currentQuantity: 0, minimumThreshold: 0,
                unitCost: 0, warehouseID: UUID()
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Name cannot be empty."))
        }
    }

    func testRecordMovement_stockIn_increasesQuantity() async throws {
        let (service, _, _) = makeSUT()
        let warehouseID = UUID()
        let item = try await service.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: warehouseID
        )

        let movement = try await service.recordMovement(
            itemID: item.id, type: .stockIn, quantity: 20, note: "Restock", referenceNumber: nil
        )

        XCTAssertEqual(movement.movementType, .stockIn)
        XCTAssertEqual(movement.quantity, 20)
        let updatedItem = try await service.getItem(byID: item.id)
        XCTAssertEqual(updatedItem.currentQuantity, 70)
    }

    func testRecordMovement_stockOut_decreasesQuantity() async throws {
        let (service, _, _) = makeSUT()
        let warehouseID = UUID()
        let item = try await service.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: warehouseID
        )

        let movement = try await service.recordMovement(
            itemID: item.id, type: .stockOut, quantity: 15, note: nil, referenceNumber: "PO-001"
        )

        XCTAssertEqual(movement.movementType, .stockOut)
        XCTAssertEqual(movement.quantity, 15)
        let updatedItem = try await service.getItem(byID: item.id)
        XCTAssertEqual(updatedItem.currentQuantity, 35)
    }

    func testRecordMovement_insufficientStock_throws() async throws {
        let (service, _, _) = makeSUT()
        let warehouseID = UUID()
        let item = try await service.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 5, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: warehouseID
        )

        do {
            _ = try await service.recordMovement(
                itemID: item.id, type: .stockOut, quantity: 10, note: nil, referenceNumber: nil
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .insufficientStock(itemName: "Widget", available: 5, requested: 10))
        }
    }

    func testRecordMovement_zeroQuantity_throws() async throws {
        let (service, _, _) = makeSUT()
        let warehouseID = UUID()
        let item = try await service.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: warehouseID
        )

        do {
            _ = try await service.recordMovement(
                itemID: item.id, type: .stockIn, quantity: 0, note: nil, referenceNumber: nil
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Quantity must be greater than zero."))
        }
    }

    func testRecordMovement_notFound_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.recordMovement(
                itemID: UUID(), type: .stockIn, quantity: 10, note: nil, referenceNumber: nil
            )
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testGetItem_notFound_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.getItem(byID: UUID())
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testDeleteItem_succeeds() async throws {
        let (service, repo, _) = makeSUT()
        let item = try await service.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 0, minimumThreshold: 0,
            unitCost: 0, warehouseID: UUID()
        )

        try await service.deleteItem(id: item.id)

        XCTAssertTrue(repo.items.isEmpty)
    }

    func testGetTotalSKUCount_returnsCorrectCount() async throws {
        let (service, _, _) = makeSUT()
        let warehouseID = UUID()
        _ = try await service.createItem(
            sku: "SKU-001", name: "A", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: warehouseID
        )
        _ = try await service.createItem(
            sku: "SKU-002", name: "B", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 20, minimumThreshold: 0,
            unitCost: 2.0, warehouseID: warehouseID
        )

        let count = try await service.getTotalSKUCount()

        XCTAssertEqual(count, 2)
    }

    func testGetTotalInventoryValue_calculatesCorrectly() async throws {
        let (service, _, _) = makeSUT()
        let warehouseID = UUID()
        _ = try await service.createItem(
            sku: "SKU-001", name: "A", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: warehouseID
        )
        _ = try await service.createItem(
            sku: "SKU-002", name: "B", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 20, minimumThreshold: 0,
            unitCost: 3.0, warehouseID: warehouseID
        )

        let value = try await service.getTotalInventoryValue()

        XCTAssertEqual(value, 110.0, accuracy: 0.01)
    }
}
