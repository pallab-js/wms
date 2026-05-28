import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class TransferServiceTests: XCTestCase {
    private func makeSUT() -> (TransferService, MockTransferOrderRepository, MockInventoryItemRepository) {
        let transferRepo = MockTransferOrderRepository()
        let itemRepo = MockInventoryItemRepository()
        let auditRepo = MockAuditRepository()
        let auditLogger = AuditLogger(repository: auditRepo)
        let service = TransferService(
            transferRepository: transferRepo,
            itemRepository: itemRepo,
            auditLogger: auditLogger
        )
        return (service, transferRepo, itemRepo)
    }

    func testCreateTransfer_validInput_succeeds() async throws {
        let (service, repo, _) = makeSUT()
        let src = UUID()
        let dst = UUID()
        let lineItems = [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: 10)]

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: dst,
            lineItems: lineItems,
            notes: "Test transfer"
        )

        XCTAssertEqual(order.sourceWarehouseID, src)
        XCTAssertEqual(order.destinationWarehouseID, dst)
        XCTAssertEqual(order.status, .draft)
        XCTAssertEqual(order.lineItems.count, 1)
        XCTAssertEqual(repo.orders.count, 1)
    }

    func testCreateTransfer_sameWarehouse_throws() async throws {
        let (service, _, _) = makeSUT()
        let sameID = UUID()

        do {
            _ = try await service.createTransfer(
                sourceWarehouseID: sameID,
                destinationWarehouseID: sameID,
                lineItems: [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: 1)],
                notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Source and destination warehouses must be different."))
        }
    }

    func testCreateTransfer_emptyLineItems_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.createTransfer(
                sourceWarehouseID: UUID(),
                destinationWarehouseID: UUID(),
                lineItems: [],
                notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Transfer must have at least one line item."))
        }
    }

    func testSubmitTransfer_fromDraft_succeeds() async throws {
        let (service, repo, _) = makeSUT()
        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: 5)],
            notes: ""
        )

        try await service.submitTransfer(id: order.id)

        XCTAssertEqual(repo.orders.first?.status, .submitted)
    }

    func testSubmitTransfer_fromNonDraft_throws() async throws {
        let (service, _, _) = makeSUT()
        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: 5)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)

        do {
            try await service.submitTransfer(id: order.id)
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .invalidTransferState(from: "submitted", to: "submitted"))
        }
    }

    func testApproveTransfer_withSufficientStock_succeeds() async throws {
        let (service, _, itemRepo) = makeSUT()
        let itemID = UUID()
        itemRepo.items = [InventoryItem(
            id: itemID,
            sku: "SKU-001",
            name: "Widget",
            currentQuantity: 100,
            warehouseID: UUID()
        )]

        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: itemID, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)

        try await service.approveTransfer(id: order.id)

        XCTAssertEqual(itemRepo.items.first?.currentQuantity, 100)
    }

    func testApproveTransfer_insufficientStock_throws() async throws {
        let (service, _, itemRepo) = makeSUT()
        let itemID = UUID()
        itemRepo.items = [InventoryItem(
            id: itemID,
            sku: "SKU-001",
            name: "Widget",
            currentQuantity: 5,
            warehouseID: UUID()
        )]

        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: itemID, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)

        do {
            try await service.approveTransfer(id: order.id)
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .insufficientStock(itemName: "Widget", available: 5, requested: 10))
        }
    }

    func testExecuteTransfer_deductsStockFromSource() async throws {
        let (service, _, itemRepo) = makeSUT()
        let itemID = UUID()
        itemRepo.items = [InventoryItem(
            id: itemID,
            sku: "SKU-001",
            name: "Widget",
            currentQuantity: 100,
            warehouseID: UUID()
        )]

        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: itemID, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)

        try await service.executeTransfer(id: order.id)

        XCTAssertEqual(itemRepo.items.first?.currentQuantity, 90)
    }

    func testCompleteTransfer_addsStockToDestination() async throws {
        let (service, _, itemRepo) = makeSUT()
        let itemID = UUID()
        itemRepo.items = [InventoryItem(
            id: itemID,
            sku: "SKU-001",
            name: "Widget",
            currentQuantity: 100,
            warehouseID: UUID()
        )]

        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: itemID, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)
        try await service.executeTransfer(id: order.id)

        try await service.completeTransfer(id: order.id)

        XCTAssertEqual(itemRepo.items.first?.currentQuantity, 100)
        XCTAssertEqual(repo.orders.first?.status, .completed)
    }

    func testCompleteTransfer_withZeroTransferredQuantity_throws() async throws {
        let (service, transferRepo, itemRepo) = makeSUT()
        let itemID = UUID()
        itemRepo.items = [InventoryItem(
            id: itemID,
            sku: "SKU-001",
            name: "Widget",
            currentQuantity: 100,
            warehouseID: UUID()
        )]

        var order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: itemID, requestedQuantity: 10)],
            notes: ""
        )
        order.status = .inTransit
        order.lineItems[0].transferredQuantity = 0
        transferRepo.orders = [order]

        do {
            try await service.completeTransfer(id: order.id)
            XCTFail("Expected error for zero transferred quantity")
        } catch let error as WMSError {
            if case .validationError(let msg) = error {
                XCTAssertTrue(msg.contains("zero transferred quantity"))
            } else {
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testCancelTransfer_fromSubmitted_succeeds() async throws {
        let (service, repo, _) = makeSUT()
        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: 5)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)

        try await service.cancelTransfer(id: order.id)

        XCTAssertEqual(repo.orders.first?.status, .cancelled)
    }

    func testCancelTransfer_fromCompleted_throws() async throws {
        let (service, _, itemRepo) = makeSUT()
        let itemID = UUID()
        itemRepo.items = [InventoryItem(
            id: itemID, sku: "SKU-001", name: "W", currentQuantity: 100, warehouseID: UUID()
        )]

        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: itemID, requestedQuantity: 5)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)
        try await service.executeTransfer(id: order.id)
        try await service.completeTransfer(id: order.id)

        do {
            try await service.cancelTransfer(id: order.id)
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .invalidTransferState(from: "completed", to: "cancelled"))
        }
    }

    func testGetTransfer_notFound_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.getTransfer(byID: UUID())
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }
}
