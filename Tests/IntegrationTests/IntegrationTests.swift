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
        let warehouseService = WarehouseService(
            repository: warehouseRepo,
            inventoryService: inventoryService,
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

    // MARK: - Edge Cases & Bug Regression Tests

    func testAdjustmentSetsAbsoluteQuantity() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: wh.id
        )
        _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .adjustment, quantity: 25, note: "Count correction", referenceNumber: nil)
        let updated = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(updated.currentQuantity, 25, "Adjustment should set absolute quantity, not delta")
    }

    func testDeleteWarehouseWithInventoryThrows() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        _ = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )
        do {
            try await s.warehouseService.deleteWarehouse(id: wh.id)
            XCTFail("Expected error when deleting warehouse with inventory")
        } catch let error as WMSError {
            if case .validationError(let msg) = error {
                XCTAssertTrue(msg.contains("inventory"))
            } else {
                XCTFail("Expected validationError, got \(error)")
            }
        }
    }

    func testCreateWarehouseTrimsWhitespace() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(
            name: "  Main Warehouse  ", code: "  WH-001  ", address: "  123 St  ", capacity: 500
        )
        XCTAssertEqual(wh.name, "Main Warehouse")
        XCTAssertEqual(wh.code, "WH-001")
        XCTAssertEqual(wh.address, "123 St")
    }

    func testUpdateWarehouseTrimsWhitespace() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        var wh = try await s.warehouseService.createWarehouse(name: "Original", code: "WH-001", address: "", capacity: 100)
        wh.name = "  Updated Name  "
        wh.code = "  WH-002  "
        try await s.warehouseService.updateWarehouse(wh)
        let fetched = try await s.warehouseService.getWarehouse(byID: wh.id)
        XCTAssertEqual(fetched.name, "Updated Name")
        XCTAssertEqual(fetched.code, "WH-002")
    }

    func testUpdateEmployeeTrimsWhitespace() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        var emp = try await s.employeeService.createEmployee(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
            jobTitle: "Manager", email: "john@test.com", phone: "",
            hireDate: Date(), notes: ""
        )
        emp.firstName = "  JohnUpdated  "
        emp.lastName = "  Smith  "
        try await s.employeeService.updateEmployee(emp)
        let fetched = try await s.employeeService.getEmployee(byID: emp.id)
        XCTAssertEqual(fetched.firstName, "JohnUpdated")
        XCTAssertEqual(fetched.lastName, "Smith")
    }

    func testUpdateItemTrimsWhitespace() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        var item = try await s.inventoryService.createItem(
            sku: "SKU-001", name: "Widget", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )
        item.name = "  Super Widget  "
        item.sku = "  SKU-002  "
        try await s.inventoryService.updateItem(item)
        let fetched = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(fetched.name, "Super Widget")
        XCTAssertEqual(fetched.sku, "SKU-002")
    }

    func testMultiItemTransferStateMachine() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
        let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
        let itemA = try await s.inventoryService.createItem(
            sku: "SKU-A", name: "Item A", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 5.0, warehouseID: src.id
        )
        let itemB = try await s.inventoryService.createItem(
            sku: "SKU-B", name: "Item B", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0,
            unitCost: 10.0, warehouseID: src.id
        )

        let order = try await s.transferService.createTransfer(
            sourceWarehouseID: src.id, destinationWarehouseID: dst.id,
            lineItems: [
                TransferLineItem(inventoryItemID: itemA.id, requestedQuantity: 30),
                TransferLineItem(inventoryItemID: itemB.id, requestedQuantity: 20),
            ],
            notes: "Multi-item transfer"
        )
        XCTAssertEqual(order.status, .draft)

        try await s.transferService.submitTransfer(id: order.id)
        try await s.transferService.approveTransfer(id: order.id)
        try await s.transferService.executeTransfer(id: order.id)

        let aAfterExec = try await s.inventoryService.getItem(byID: itemA.id)
        let bAfterExec = try await s.inventoryService.getItem(byID: itemB.id)
        XCTAssertEqual(aAfterExec.currentQuantity, 70)
        XCTAssertEqual(bAfterExec.currentQuantity, 30)

        try await s.transferService.completeTransfer(id: order.id)
        let aAfterComplete = try await s.inventoryService.getItem(byID: itemA.id)
        let bAfterComplete = try await s.inventoryService.getItem(byID: itemB.id)
        XCTAssertEqual(aAfterComplete.currentQuantity, 70)
        XCTAssertEqual(bAfterComplete.currentQuantity, 30)
    }

    func testEmptyJsonFileDoesNotCrash() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wms_empty_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let store = WMSDataStore(baseURL: tmp)
        let whRepo = FileWarehouseRepository(store: store)
        let warehouses = try await whRepo.fetchAll()
        XCTAssertTrue(warehouses.isEmpty, "Empty file should result in empty array, not crash")
    }

    func testDataPersistsAcrossServiceRecreation() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wms_persist_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let store1 = WMSDataStore(baseURL: tmp)
        let s1 = makeServices(store1)
        let wh = try await s1.warehouseService.createWarehouse(name: "Persistent", code: "WH-P", address: "", capacity: 500)
        let item = try await s1.inventoryService.createItem(
            sku: "SKU-P", name: "Persist Item", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )

        let store2 = WMSDataStore(baseURL: tmp)
        let s2 = makeServices(store2)
        let fetchedWH = try await s2.warehouseService.getWarehouse(byID: wh.id)
        XCTAssertEqual(fetchedWH.name, "Persistent")
        let fetchedItem = try await s2.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(fetchedItem.currentQuantity, 100)
    }

    func testTransferWithZeroQuantityItem() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let src = try await s.warehouseService.createWarehouse(name: "Src", code: "WH-S", address: "", capacity: 1000)
        let dst = try await s.warehouseService.createWarehouse(name: "Dst", code: "WH-D", address: "", capacity: 1000)
        let _ = try await s.inventoryService.createItem(
            sku: "SKU-Z", name: "Zero Qty", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 0, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: src.id
        )
        let items = try await s.inventoryService.getAllItems(forWarehouseID: src.id)
        let zeroItem = items.first(where: { $0.currentQuantity == 0 })!
        let order = try await s.transferService.createTransfer(
            sourceWarehouseID: src.id, destinationWarehouseID: dst.id,
            lineItems: [TransferLineItem(inventoryItemID: zeroItem.id, requestedQuantity: 5)],
            notes: "Transfer zero-qty item"
        )
        XCTAssertEqual(order.lineItems.count, 1)
    }

    // MARK: - Concurrency Safety Tests

    func testConcurrentStockMovementsDoNotCorruptData() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 1000)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-C", name: "Concurrent", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 1000, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    let s2 = self.makeServices(store)
                    _ = try await s2.inventoryService.recordMovement(
                        itemID: item.id, type: .stockIn, quantity: 10, note: nil, referenceNumber: nil
                    )
                }
            }
            try await group.waitForAll()
        }

        let final = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(final.currentQuantity, 1200, "All 20 stockIn movements should sum correctly")
    }

    func testConcurrentReadsAndWritesDoNotDeadlock() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 1000)
        let item = try await s.inventoryService.createItem(
            sku: "SKU-D", name: "Deadlock Test", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )

        try await withThrowingTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let s2 = self.makeServices(store)
                    if i.isMultiple(of: 2) {
                        _ = try await s2.inventoryService.recordMovement(
                            itemID: item.id, type: .stockOut, quantity: 1, note: nil, referenceNumber: nil
                        )
                    } else {
                        _ = try await s2.inventoryService.getItem(byID: item.id)
                    }
                }
            }
            try await group.waitForAll()
        }

        let final = try await s.inventoryService.getItem(byID: item.id)
        XCTAssertEqual(final.currentQuantity, 95, "5 stockOut movements should have occurred")
    }

    // MARK: - Error Propagation Tests

    func testServicePropagatesPersistenceError() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wms_error_test_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let store = WMSDataStore(baseURL: tmp)
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)

        try FileManager.default.removeItem(at: tmp.appendingPathComponent("warehouses.json"))

        do {
            _ = try await s.warehouseService.getWarehouse(byID: wh.id)
            XCTFail("Expected error after deleting backing file")
        } catch {
            XCTAssertTrue(error is WMSError, "Service should wrap raw error in WMSError")
        }
    }

    func testServicePropagatesFetchAllError() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wms_fetchall_error_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let store = WMSDataStore(baseURL: tmp)
        let s = makeServices(store)
        let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
        _ = try await s.inventoryService.createItem(
            sku: "SKU-E", name: "Error Item", description: "", category: "",
            unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0,
            unitCost: 1.0, warehouseID: wh.id
        )

        try FileManager.default.removeItem(at: tmp.appendingPathComponent("inventory_items.json"))

        do {
            _ = try await s.inventoryService.getAllItems(forWarehouseID: wh.id)
            XCTFail("Expected error after deleting backing file")
        } catch {
            XCTAssertTrue(error is WMSError, "Service should wrap data errors in WMSError")
        }
    }

    // MARK: - Audit Role Integration Test

    func testAuditLoggerRespectsCurrentUserRole() async throws {
        let store = makeTempStore()
        let s = makeServices(store)
        let auditRepo = FileAuditRepository(store: store)

        s.auditLogger.currentUserRole = .manager
        let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-002", address: "", capacity: 100)
        let entries = try await auditRepo.fetchAll(entityType: "Warehouse", startDate: nil, endDate: nil, action: "created")
        XCTAssertEqual(entries.first?.userRole, "manager")
    }
}
