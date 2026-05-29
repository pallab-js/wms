import XCTest
import WMSCore
import WMSData
import WMSServices

final class IntegrationTests: XCTestCase {
    func makeTempStore() -> WMSDataStore {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wms_test_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        return WMSDataStore(baseURL: tmp)
    }

    func makeServices(_ store: WMSDataStore) -> (
        warehouseService: WarehouseService,
        inventoryService: InventoryService,
        employeeService: EmployeeService,
        transferService: TransferService,
        dashboardService: DashboardService,
        auditLogger: AuditLogger
    ) {
        let warehouseRepo = FileWarehouseRepository(store: store)
        let inventoryRepo = FileInventoryItemRepository(store: store)
        let movementRepo = FileStockMovementRepository(store: store)
        let employeeRepo = FileEmployeeRepository(store: store)
        let transferRepo = FileTransferOrderRepository(store: store)
        let auditRepo = FileAuditRepository(store: store)
        let alertRepo = FileAlertRepository(store: store)

        let auditLogger = AuditLogger(repository: auditRepo)
        let alertService = InventoryAlertService(alertRepository: alertRepo)

        let warehouseService = WarehouseService(repository: warehouseRepo, auditLogger: auditLogger)
        let inventoryService = InventoryService(
            itemRepository: inventoryRepo,
            movementRepository: movementRepo,
            alertService: alertService,
            auditLogger: auditLogger
        )
        let employeeService = EmployeeService(repository: employeeRepo, auditLogger: auditLogger)
        let transferService = TransferService(
            transferRepository: transferRepo,
            itemRepository: inventoryRepo,
            auditLogger: auditLogger
        )
        let stockMovementService = StockMovementService(movementRepository: movementRepo)
        let dashboardService = DashboardService(
            warehouseRepository: warehouseRepo,
            inventoryService: inventoryService,
            movementService: stockMovementService
        )

        return (warehouseService, inventoryService, employeeService, transferService, dashboardService, auditLogger)
    }

    // MARK: - Warehouse Tests

    func testWarehouseCreateAndFetch() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "Main", code: "WH-001", address: "123 St", capacity: 500)
        XCTAssertEqual(wh.name, "Main")
        XCTAssertEqual(wh.code, "WH-001")
        XCTAssertEqual(wh.capacity, 500)
        XCTAssertTrue(wh.isActive)
    }

    func testWarehouseFetchAll() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        _ = try await s.warehouseService.createWarehouse(name: "A", code: "WH-A", address: "", capacity: 100)
        _ = try await s.warehouseService.createWarehouse(name: "B", code: "WH-B", address: "", capacity: 200)
        let all = try await s.warehouseService.getAllWarehouses()
        XCTAssertEqual(all.count, 2)
    }

    func testWarehouseDuplicateCodeThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        _ = try await s.warehouseService.createWarehouse(name: "First", code: "WH-001", address: "", capacity: 100)
        do {
            _ = try await s.warehouseService.createWarehouse(name: "Second", code: "WH-001", address: "", capacity: 100)
            XCTFail("Expected duplicate code error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testWarehouseUpdate() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        var wh = try await s.warehouseService.createWarehouse(name: "Original", code: "WH-001", address: "", capacity: 100)
        wh.name = "Updated"
        try await s.warehouseService.updateWarehouse(wh)
        let fetched = try await s.warehouseService.getWarehouse(byID: wh.id)
        XCTAssertEqual(fetched.name, "Updated")
    }

    func testWarehouseDeactivate() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 100)
        try await s.warehouseService.deactivateWarehouse(id: wh.id)
        let fetched = try await s.warehouseService.getWarehouse(byID: wh.id)
        XCTAssertFalse(fetched.isActive)
    }

    func testWarehouseDelete() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 100)
        try await s.warehouseService.deleteWarehouse(id: wh.id)
        let all = try await s.warehouseService.getAllWarehouses()
        XCTAssertTrue(all.isEmpty)
    }

    func testWarehouseEmptyNameThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        do {
            _ = try await s.warehouseService.createWarehouse(name: "", code: "WH-001", address: "", capacity: 100)
            XCTFail("Expected validation error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    // MARK: - Inventory Tests

    func testInventoryCreateItem() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "desc", category: "Parts",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 10,
            unitCost: 9.99, warehouseID: wh.id
        )
        XCTAssertEqual(item.sku, "SKU-001")
        XCTAssertEqual(item.currentQuantity, 50)
    }

    func testInventoryStockIn() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: wh.id
        )
        _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockIn, quantity: 25, note: "Restock", referenceNumber: "PO-001")
        let updated = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(updated.currentQuantity, 35)
    }

    func testInventoryStockOut() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: wh.id
        )
        _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockOut, quantity: 20, note: nil, referenceNumber: nil)
        let updated = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(updated.currentQuantity, 30)
    }

    func testInventoryInsufficientStockThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 5, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: wh.id
        )
        do {
            _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockOut, quantity: 10, note: nil, referenceNumber: nil)
            XCTFail("Expected insufficient stock error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testInventoryTotalValue() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        _ = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "A", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: wh.id
        )
        _ = try await s.inventoryService.createItem(
            sku: "SKU-002", name: "B", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 20, minimumThreshold: 0,
            unitCost: 3.0, warehouseID: wh.id
        )
        let value = try await s.inventoryService.getTotalInventoryValue()
        XCTAssertEqual(value, 110.0)
    }

    // MARK: - Employee Tests

    func testEmployeeCreateAndFetch() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let emp = try await s.employeeService.createEmployee(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
            jobTitle: "Manager", email: "john@test.com", phone: "555-0100",
            hireDate: Date(), notes: ""
        )
        XCTAssertEqual(emp.fullName, "John Doe")
        XCTAssertTrue(emp.isActive)
    }

    func testEmployeeDuplicateCodeThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        _ = try await s.employeeService.createEmployee(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
            jobTitle: "Manager", email: "john@test.com", phone: "",
            hireDate: Date(), notes: ""
        )
        do {
            _ = try await s.employeeService.createEmployee(
                firstName: "Jane", lastName: "Smith", employeeCode: "EMP-001",
                jobTitle: "Clerk", email: "jane@test.com", phone: "",
                hireDate: Date(), notes: ""
            )
            XCTFail("Expected duplicate code error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testEmployeeUpdate() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        var emp = try await s.employeeService.createEmployee(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
            jobTitle: "Clerk", email: "john@test.com", phone: "",
            hireDate: Date(), notes: ""
        )
        emp.jobTitle = "Manager"
        try await s.employeeService.updateEmployee(emp)
        let fetched = try await s.employeeService.getEmployee(byID: emp.id)
        XCTAssertEqual(fetched.jobTitle, "Manager")
    }

    func testEmployeeDeactivate() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let emp = try await s.employeeService.createEmployee(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
            jobTitle: "Manager", email: "john@test.com", phone: "",
            hireDate: Date(), notes: ""
        )
        try await s.employeeService.deactivateEmployee(id: emp.id)
        let fetched = try await s.employeeService.getEmployee(byID: emp.id)
        XCTAssertFalse(fetched.isActive)
    }

    func testEmployeeDelete() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let emp = try await s.employeeService.createEmployee(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
            jobTitle: "Manager", email: "john@test.com", phone: "",
            hireDate: Date(), notes: ""
        )
        try await s.employeeService.deleteEmployee(id: emp.id)
        let all = try await s.employeeService.getAllEmployees()
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - Transfer Tests

    func testTransferFullStateMachine() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
        let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: src.id
        )

        let order = try await s.transferService.createTransfer(
            sourceWarehouseID: src.id, destinationWarehouseID: dst.id,
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 30)],
            notes: "test"
        )
        XCTAssertEqual(order.status, .draft)

        try await s.transferService.submitTransfer(id: order.id)
        var fetched = try await s.transferService.getTransfer(byID: order.id)
        XCTAssertEqual(fetched.status, .submitted)

        try await s.transferService.approveTransfer(id: order.id)
        fetched = try await s.transferService.getTransfer(byID: order.id)
        XCTAssertEqual(fetched.status, .approved)

        try await s.transferService.executeTransfer(id: order.id)
        fetched = try await s.transferService.getTransfer(byID: order.id)
        XCTAssertEqual(fetched.status, .inTransit)
        let itemAfterExec = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(itemAfterExec.currentQuantity, 70)

        try await s.transferService.completeTransfer(id: order.id)
        fetched = try await s.transferService.getTransfer(byID: order.id)
        XCTAssertEqual(fetched.status, .completed)
        XCTAssertNotNil(fetched.completedDate)
    }

    func testTransferSameWarehouseThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )
        do {
            _ = try await s.transferService.createTransfer(
                sourceWarehouseID: wh.id, destinationWarehouseID: wh.id,
                lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
                notes: ""
            )
            XCTFail("Expected validation error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testTransferInvalidStateTransitionThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
        let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: src.id
        )
        let order = try await s.transferService.createTransfer(
            sourceWarehouseID: src.id, destinationWarehouseID: dst.id,
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        do {
            try await s.transferService.approveTransfer(id: order.id)
            XCTFail("Expected invalid state error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testTransferCancel() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
        let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: src.id
        )
        let order = try await s.transferService.createTransfer(
            sourceWarehouseID: src.id, destinationWarehouseID: dst.id,
            lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)],
            notes: ""
        )
        try await s.transferService.submitTransfer(id: order.id)
        try await s.transferService.cancelTransfer(id: order.id)
        let fetched = try await s.transferService.getTransfer(byID: order.id)
        XCTAssertEqual(fetched.status, .cancelled)
    }

    // MARK: - Dashboard Tests

    func testDashboardEmptyState() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let data = try await s.dashboardService.getDashboardData()
        XCTAssertEqual(data.activeWarehouseCount, 0)
        XCTAssertEqual(data.totalSKUCount, 0)
        XCTAssertTrue(data.warehouseSummaries.isEmpty)
    }

    func testDashboardWithData() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh1 = try await s.warehouseService.createWarehouse(name: "WH A", code: "WH-A", address: "", capacity: 500)
        let wh2 = try await s.warehouseService.createWarehouse(name: "WH B", code: "WH-B", address: "", capacity: 300)
        _ = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "A", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: wh1.id
        )
        _ = try await s.inventoryService.createItem(
            sku: "SKU-002", name: "B", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 10.0, warehouseID: wh2.id
        )

        let data = try await s.dashboardService.getDashboardData()
        XCTAssertEqual(data.activeWarehouseCount, 2)
        XCTAssertEqual(data.totalSKUCount, 2)
        XCTAssertEqual(data.totalInventoryValue, 1000.0)
        XCTAssertEqual(data.warehouseSummaries.count, 2)
    }

    func testDashboardInactiveWarehouseNotCounted() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh1 = try await s.warehouseService.createWarehouse(name: "Active", code: "WH-A", address: "", capacity: 100)
        let wh2 = try await s.warehouseService.createWarehouse(name: "Inactive", code: "WH-I", address: "", capacity: 100)
        try await s.warehouseService.deactivateWarehouse(id: wh2.id)
        let data = try await s.dashboardService.getDashboardData()
        XCTAssertEqual(data.activeWarehouseCount, 1)
    }

    // MARK: - Audit Trail Tests

    func testAuditWarehouseCreateProducesEntry() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let auditRepo = FileAuditRepository(store: store)
        let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 100)
        let entries = try await auditRepo.fetchAll(entityType: "Warehouse", startDate: nil, endDate: nil, action: "created")
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.entityID, wh.id)
    }

    func testAuditStockMovementProducesEntry() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let auditRepo = FileAuditRepository(store: store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )
        _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockIn, quantity: 10, note: nil, referenceNumber: nil)
        let entries = try await auditRepo.fetchAll(entityType: "StockMovement", startDate: nil, endDate: nil, action: nil)
        XCTAssertEqual(entries.count, 1)
    }
}
