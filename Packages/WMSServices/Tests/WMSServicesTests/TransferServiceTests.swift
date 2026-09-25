import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class TransferServiceTests: XCTestCase {
    private func makeSUT() -> (TransferService, MockTransferOrderRepository, MockInventoryItemRepository) {
        let transferRepo = MockTransferOrderRepository()
        let itemRepo = MockInventoryItemRepository()
        transferRepo.itemRepository = itemRepo
        let auditRepo = MockAuditRepository()
        let auditLogger = AuditLogger(repository: auditRepo)
        let service = TransferService(
            transferRepository: transferRepo,
            auditLogger: auditLogger
        )
        return (service, transferRepo, itemRepo)
    }

    private func makeItem(
        repo: MockInventoryItemRepository,
        warehouseID: UUID,
        quantity: Int
    ) -> InventoryItem {
        let item = InventoryItem(
            sku: "SKU-001",
            name: "Widget",
            currentQuantity: quantity,
            warehouseID: warehouseID
        )
        repo.items = [item]
        return item
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

    func testCreateTransfer_nonPositiveQuantity_throws() async throws {
        let (service, _, _) = makeSUT()

        do {
            _ = try await service.createTransfer(
                sourceWarehouseID: UUID(),
                destinationWarehouseID: UUID(),
                lineItems: [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: -5)],
                notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(
                error,
                .validationError("Transfer line items must request a quantity greater than zero.")
            )
        }
    }

    func testCreateTransfer_duplicateLineItem_throws() async throws {
        let (service, _, _) = makeSUT()
        let itemID = UUID()

        do {
            _ = try await service.createTransfer(
                sourceWarehouseID: UUID(),
                destinationWarehouseID: UUID(),
                lineItems: [
                    TransferLineItem(inventoryItemID: itemID, requestedQuantity: 5),
                    TransferLineItem(inventoryItemID: itemID, requestedQuantity: 5),
                ],
                notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(
                error,
                .validationError("Each inventory item may appear only once per transfer.")
            )
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
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)

        try await service.approveTransfer(id: order.id)

        XCTAssertEqual(itemRepo.items.first?.currentQuantity, 100)
    }

    func testApproveTransfer_insufficientStock_throws() async throws {
        let (service, _, itemRepo) = makeSUT()
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 5)

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
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

    func testApproveTransfer_itemFromAnotherWarehouse_throws() async throws {
        let (service, _, itemRepo) = makeSUT()
        let item = makeItem(repo: itemRepo, warehouseID: UUID(), quantity: 100)

        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)

        do {
            try await service.approveTransfer(id: order.id)
            XCTFail("Expected error")
        } catch let error as WMSError {
            guard case .validationError(let message) = error else {
                return XCTFail("Expected validationError, got \(error)")
            }
            XCTAssertTrue(message.contains("not stored in the source warehouse"))
        }
    }

    func testApproveTransfer_aggregatesDuplicateLines_throws() async throws {
        let (service, transferRepo, itemRepo) = makeSUT()
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        var order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 60)],
            notes: ""
        )
        order.lineItems.append(TransferLineItem(inventoryItemID: item.id, requestedQuantity: 60))
        transferRepo.orders = [order]
        try await service.submitTransfer(id: order.id)

        do {
            try await service.approveTransfer(id: order.id)
            XCTFail("Expected error for aggregated over-request")
        } catch let error as WMSError {
            XCTAssertEqual(error, .insufficientStock(itemName: "Widget", available: 100, requested: 120))
        }
    }

    func testExecuteTransfer_deductsStockFromSource() async throws {
        let (service, _, itemRepo) = makeSUT()
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)

        try await service.executeTransfer(id: order.id)

        XCTAssertEqual(itemRepo.items.first?.currentQuantity, 90)
        XCTAssertEqual(itemRepo.items.first?.warehouseID, src, "Source record must stay in the source warehouse")
    }

    func testExecuteTransfer_twice_throws() async throws {
        let (service, _, itemRepo) = makeSUT()
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)
        try await service.executeTransfer(id: order.id)

        do {
            try await service.executeTransfer(id: order.id)
            XCTFail("Expected error on second execution")
        } catch let error as WMSError {
            XCTAssertEqual(error, .invalidTransferState(from: "inTransit", to: "inTransit"))
        }
        XCTAssertEqual(itemRepo.items.first?.currentQuantity, 90, "Stock must only be deducted once")
    }

    func testCompleteTransfer_addsStockToDestination() async throws {
        let (service, repo, itemRepo) = makeSUT()
        let src = UUID()
        let dst = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: dst,
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)
        try await service.executeTransfer(id: order.id)

        try await service.completeTransfer(id: order.id)

        XCTAssertEqual(
            itemRepo.items.first(where: { $0.id == item.id })?.currentQuantity,
            90,
            "Source keeps only the un-transferred remainder"
        )
        let destination = itemRepo.items.first { $0.warehouseID == dst }
        XCTAssertEqual(destination?.currentQuantity, 10, "Destination receives the transferred stock")
        XCTAssertEqual(destination?.sku, item.sku)
        XCTAssertEqual(repo.orders.first?.status, .completed)
    }

    func testCompleteTransfer_mergesIntoExistingDestinationItem() async throws {
        let (service, _, itemRepo) = makeSUT()
        let src = UUID()
        let dst = UUID()
        let sourceItem = InventoryItem(
            sku: "SKU-001", name: "Widget", currentQuantity: 100, warehouseID: src
        )
        let destinationItem = InventoryItem(
            sku: "SKU-001", name: "Widget", currentQuantity: 25, warehouseID: dst
        )
        itemRepo.items = [sourceItem, destinationItem]

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: dst,
            lineItems: [TransferLineItem(inventoryItemID: sourceItem.id, requestedQuantity: 10)],
            notes: ""
        )
        try await service.submitTransfer(id: order.id)
        try await service.approveTransfer(id: order.id)
        try await service.executeTransfer(id: order.id)
        try await service.completeTransfer(id: order.id)

        XCTAssertEqual(itemRepo.items.count, 2, "Existing destination SKU should be merged, not duplicated")
        XCTAssertEqual(itemRepo.items.first { $0.id == destinationItem.id }?.currentQuantity, 35)
    }

    func testCompleteTransfer_withZeroTransferredQuantity_throws() async throws {
        let (service, transferRepo, itemRepo) = makeSUT()
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        var order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
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

    func testCancelTransfer_fromDraft_succeeds() async throws {
        let (service, repo, _) = makeSUT()
        let order = try await service.createTransfer(
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: UUID(), requestedQuantity: 5)],
            notes: ""
        )

        try await service.cancelTransfer(id: order.id)

        XCTAssertEqual(repo.orders.first?.status, .cancelled)
    }

    func testCancelTransfer_fromCompleted_throws() async throws {
        let (service, _, itemRepo) = makeSUT()
        let src = UUID()
        let item = makeItem(repo: itemRepo, warehouseID: src, quantity: 100)

        let order = try await service.createTransfer(
            sourceWarehouseID: src,
            destinationWarehouseID: UUID(),
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 5)],
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
