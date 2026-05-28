import Foundation
import WMSCore
import WMSData
import WMSServices

var passed = 0
var failed = 0
var errors: [String] = []

func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
    if condition {
        passed += 1
    } else {
        failed += 1
        let fname = (file as NSString).lastPathComponent
        let msg = "[FAIL] \(fname):\(line) — \(message)"
        errors.append(msg)
        print(msg)
    }
}

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
    assert(a == b, "\(message) expected \(b), got \(a)", file: file, line: line)
}

func assertTrue(_ value: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    assert(value, message, file: file, line: line)
}

func assertFalse(_ value: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    assert(!value, message, file: file, line: line)
}

func test(_ name: String, _ body: () async throws -> Void) async {
    do {
        try await body()
        print("[PASS] \(name)")
    } catch {
        failed += 1
        let msg = "[FAIL] \(name) — \(error.localizedDescription)"
        errors.append(msg)
        print(msg)
    }
}

func makeTempStore() -> WMSDataStore {
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("wms_test_\(UUID().uuidString)")
    try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    return WMSDataStore(baseURL: tmp)
}

func makeServices(_ store: WMSDataStore) -> (warehouseService: WarehouseService, inventoryService: InventoryService, employeeService: EmployeeService, transferService: TransferService, dashboardService: DashboardService, auditLogger: AuditLogger) {
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
    let inventoryService = InventoryService(itemRepository: inventoryRepo, movementRepository: movementRepo, alertService: alertService, auditLogger: auditLogger)
    let employeeService = EmployeeService(repository: employeeRepo, auditLogger: auditLogger)
    let transferService = TransferService(transferRepository: transferRepo, itemRepository: inventoryRepo, auditLogger: auditLogger)
    let stockMovementService = StockMovementService(movementRepository: movementRepo)
    let dashboardService = DashboardService(warehouseRepository: warehouseRepo, inventoryService: inventoryService, movementService: stockMovementService)

    return (warehouseService, inventoryService, employeeService, transferService, dashboardService, auditLogger)
}

@main
struct TestRunner {
    static func main() async {
        // Warehouse Tests
        await test("Warehouse: create and fetch") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "Main", code: "WH-001", address: "123 St", capacity: 500)
            assertEqual(wh.name, "Main")
            assertEqual(wh.code, "WH-001")
            assertEqual(wh.capacity, 500)
            assertTrue(wh.isActive)
        }

        await test("Warehouse: fetch all") {
            let store = makeTempStore()
            let s = makeServices(store)
            _ = try await s.warehouseService.createWarehouse(name: "A", code: "WH-A", address: "", capacity: 100)
            _ = try await s.warehouseService.createWarehouse(name: "B", code: "WH-B", address: "", capacity: 200)
            let all = try await s.warehouseService.getAllWarehouses()
            assertEqual(all.count, 2)
        }

        await test("Warehouse: duplicate code throws") {
            let store = makeTempStore()
            let s = makeServices(store)
            _ = try await s.warehouseService.createWarehouse(name: "First", code: "WH-001", address: "", capacity: 100)
            do {
                _ = try await s.warehouseService.createWarehouse(name: "Second", code: "WH-001", address: "", capacity: 100)
                assert(false, "Expected duplicate code error")
            } catch {
                assertTrue(error is WMSError)
            }
        }

        await test("Warehouse: update") {
            let store = makeTempStore()
            let s = makeServices(store)
            var wh = try await s.warehouseService.createWarehouse(name: "Original", code: "WH-001", address: "", capacity: 100)
            wh.name = "Updated"
            try await s.warehouseService.updateWarehouse(wh)
            let fetched = try await s.warehouseService.getWarehouse(byID: wh.id)
            assertEqual(fetched.name, "Updated")
        }

        await test("Warehouse: deactivate") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 100)
            try await s.warehouseService.deactivateWarehouse(id: wh.id)
            let fetched = try await s.warehouseService.getWarehouse(byID: wh.id)
            assertFalse(fetched.isActive)
        }

        await test("Warehouse: delete") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 100)
            try await s.warehouseService.deleteWarehouse(id: wh.id)
            let all = try await s.warehouseService.getAllWarehouses()
            assertTrue(all.isEmpty)
        }

        await test("Warehouse: empty name throws") {
            let store = makeTempStore()
            let s = makeServices(store)
            do {
                _ = try await s.warehouseService.createWarehouse(name: "", code: "WH-001", address: "", capacity: 100)
                assert(false, "Expected validation error")
            } catch {
                assertTrue(error is WMSError)
            }
        }

        // Inventory Tests
        await test("Inventory: create item") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "desc", category: "Parts", unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 10, unitCost: 9.99, warehouseID: wh.id)
            assertEqual(item.sku, "SKU-001")
            assertEqual(item.currentQuantity, 50)
        }

        await test("Inventory: stock in") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0, unitCost: 5.0, warehouseID: wh.id)
            _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockIn, quantity: 25, note: "Restock", referenceNumber: "PO-001")
            let updated = try await s.inventoryService.getItem(byID: item.id)
            assertEqual(updated.currentQuantity, 35)
        }

        await test("Inventory: stock out") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0, unitCost: 5.0, warehouseID: wh.id)
            _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockOut, quantity: 20, note: nil, referenceNumber: nil)
            let updated = try await s.inventoryService.getItem(byID: item.id)
            assertEqual(updated.currentQuantity, 30)
        }

        await test("Inventory: insufficient stock throws") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 5, minimumThreshold: 0, unitCost: 5.0, warehouseID: wh.id)
            do {
                _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockOut, quantity: 10, note: nil, referenceNumber: nil)
                assert(false, "Expected insufficient stock error")
            } catch {
                assertTrue(error is WMSError)
            }
        }

        await test("Inventory: total value") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            _ = try await s.inventoryService.createItem(sku: "SKU-001", name: "A", description: "", category: "", unitOfMeasure: "units", currentQuantity: 10, minimumThreshold: 0, unitCost: 5.0, warehouseID: wh.id)
            _ = try await s.inventoryService.createItem(sku: "SKU-002", name: "B", description: "", category: "", unitOfMeasure: "units", currentQuantity: 20, minimumThreshold: 0, unitCost: 3.0, warehouseID: wh.id)
            let value = try await s.inventoryService.getTotalInventoryValue()
            assertEqual(value, 110.0)
        }

        // Employee Tests
        await test("Employee: create and fetch") {
            let store = makeTempStore()
            let s = makeServices(store)
            let emp = try await s.employeeService.createEmployee(firstName: "John", lastName: "Doe", employeeCode: "EMP-001", jobTitle: "Manager", email: "john@test.com", phone: "555-0100", hireDate: Date(), notes: "")
            assertEqual(emp.fullName, "John Doe")
            assertTrue(emp.isActive)
        }

        await test("Employee: duplicate code throws") {
            let store = makeTempStore()
            let s = makeServices(store)
            _ = try await s.employeeService.createEmployee(firstName: "John", lastName: "Doe", employeeCode: "EMP-001", jobTitle: "Manager", email: "john@test.com", phone: "", hireDate: Date(), notes: "")
            do {
                _ = try await s.employeeService.createEmployee(firstName: "Jane", lastName: "Smith", employeeCode: "EMP-001", jobTitle: "Clerk", email: "jane@test.com", phone: "", hireDate: Date(), notes: "")
                assert(false, "Expected duplicate code error")
            } catch {
                assertTrue(error is WMSError)
            }
        }

        await test("Employee: update") {
            let store = makeTempStore()
            let s = makeServices(store)
            var emp = try await s.employeeService.createEmployee(firstName: "John", lastName: "Doe", employeeCode: "EMP-001", jobTitle: "Clerk", email: "john@test.com", phone: "", hireDate: Date(), notes: "")
            emp.jobTitle = "Manager"
            try await s.employeeService.updateEmployee(emp)
            let fetched = try await s.employeeService.getEmployee(byID: emp.id)
            assertEqual(fetched.jobTitle, "Manager")
        }

        await test("Employee: deactivate") {
            let store = makeTempStore()
            let s = makeServices(store)
            let emp = try await s.employeeService.createEmployee(firstName: "John", lastName: "Doe", employeeCode: "EMP-001", jobTitle: "Manager", email: "john@test.com", phone: "", hireDate: Date(), notes: "")
            try await s.employeeService.deactivateEmployee(id: emp.id)
            let fetched = try await s.employeeService.getEmployee(byID: emp.id)
            assertFalse(fetched.isActive)
        }

        await test("Employee: delete") {
            let store = makeTempStore()
            let s = makeServices(store)
            let emp = try await s.employeeService.createEmployee(firstName: "John", lastName: "Doe", employeeCode: "EMP-001", jobTitle: "Manager", email: "john@test.com", phone: "", hireDate: Date(), notes: "")
            try await s.employeeService.deleteEmployee(id: emp.id)
            let all = try await s.employeeService.getAllEmployees()
            assertTrue(all.isEmpty)
        }

        // Transfer Tests
        await test("Transfer: full state machine") {
            let store = makeTempStore()
            let s = makeServices(store)
            let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
            let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0, unitCost: 5.0, warehouseID: src.id)

            let order = try await s.transferService.createTransfer(sourceWarehouseID: src.id, destinationWarehouseID: dst.id, lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 30)], notes: "test")
            assertEqual(order.status, .draft)

            try await s.transferService.submitTransfer(id: order.id)
            var fetched = try await s.transferService.getTransfer(byID: order.id)
            assertEqual(fetched.status, .submitted)

            try await s.transferService.approveTransfer(id: order.id)
            fetched = try await s.transferService.getTransfer(byID: order.id)
            assertEqual(fetched.status, .approved)

            try await s.transferService.executeTransfer(id: order.id)
            fetched = try await s.transferService.getTransfer(byID: order.id)
            assertEqual(fetched.status, .inTransit)
            let itemAfterExec = try await s.inventoryService.getItem(byID: item.id)
            assertEqual(itemAfterExec.currentQuantity, 70)

            try await s.transferService.completeTransfer(id: order.id)
            fetched = try await s.transferService.getTransfer(byID: order.id)
            assertEqual(fetched.status, .completed)
            assertTrue(fetched.completedDate != nil)
        }

        await test("Transfer: same warehouse throws") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0, unitCost: 1.0, warehouseID: wh.id)
            do {
                _ = try await s.transferService.createTransfer(sourceWarehouseID: wh.id, destinationWarehouseID: wh.id, lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)], notes: "")
                assert(false, "Expected validation error")
            } catch {
                assertTrue(error is WMSError)
            }
        }

        await test("Transfer: invalid state transition throws") {
            let store = makeTempStore()
            let s = makeServices(store)
            let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
            let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0, unitCost: 1.0, warehouseID: src.id)
            let order = try await s.transferService.createTransfer(sourceWarehouseID: src.id, destinationWarehouseID: dst.id, lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)], notes: "")
            do {
                try await s.transferService.approveTransfer(id: order.id)
                assert(false, "Expected invalid state error")
            } catch {
                assertTrue(error is WMSError)
            }
        }

        await test("Transfer: cancel") {
            let store = makeTempStore()
            let s = makeServices(store)
            let src = try await s.warehouseService.createWarehouse(name: "Source", code: "WH-S", address: "", capacity: 1000)
            let dst = try await s.warehouseService.createWarehouse(name: "Dest", code: "WH-D", address: "", capacity: 1000)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0, unitCost: 1.0, warehouseID: src.id)
            let order = try await s.transferService.createTransfer(sourceWarehouseID: src.id, destinationWarehouseID: dst.id, lineItems: [TransferLineItem(inventoryItemID: item.id, requestedQuantity: 10)], notes: "")
            try await s.transferService.submitTransfer(id: order.id)
            try await s.transferService.cancelTransfer(id: order.id)
            let fetched = try await s.transferService.getTransfer(byID: order.id)
            assertEqual(fetched.status, .cancelled)
        }

        // Dashboard Tests
        await test("Dashboard: empty state") {
            let store = makeTempStore()
            let s = makeServices(store)
            let data = try await s.dashboardService.getDashboardData()
            assertEqual(data.activeWarehouseCount, 0)
            assertEqual(data.totalSKUCount, 0)
            assertTrue(data.warehouseSummaries.isEmpty)
        }

        await test("Dashboard: with data") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh1 = try await s.warehouseService.createWarehouse(name: "WH A", code: "WH-A", address: "", capacity: 500)
            let wh2 = try await s.warehouseService.createWarehouse(name: "WH B", code: "WH-B", address: "", capacity: 300)
            _ = try await s.inventoryService.createItem(sku: "SKU-001", name: "A", description: "", category: "", unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0, unitCost: 5.0, warehouseID: wh1.id)
            _ = try await s.inventoryService.createItem(sku: "SKU-002", name: "B", description: "", category: "", unitOfMeasure: "units", currentQuantity: 50, minimumThreshold: 0, unitCost: 10.0, warehouseID: wh2.id)

            let data = try await s.dashboardService.getDashboardData()
            assertEqual(data.activeWarehouseCount, 2)
            assertEqual(data.totalSKUCount, 2)
            assertEqual(data.totalInventoryValue, 1000.0)
            assertEqual(data.warehouseSummaries.count, 2)
        }

        await test("Dashboard: inactive warehouse not counted") {
            let store = makeTempStore()
            let s = makeServices(store)
            let wh1 = try await s.warehouseService.createWarehouse(name: "Active", code: "WH-A", address: "", capacity: 100)
            let wh2 = try await s.warehouseService.createWarehouse(name: "Inactive", code: "WH-I", address: "", capacity: 100)
            try await s.warehouseService.deactivateWarehouse(id: wh2.id)
            let data = try await s.dashboardService.getDashboardData()
            assertEqual(data.activeWarehouseCount, 1)
        }

        // Audit Trail Tests
        await test("Audit: warehouse create produces entry") {
            let store = makeTempStore()
            let s = makeServices(store)
            let auditRepo = FileAuditRepository(store: store)
            let wh = try await s.warehouseService.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 100)
            let entries = try await auditRepo.fetchAll(entityType: "Warehouse", startDate: nil, endDate: nil, action: "created")
            assertEqual(entries.count, 1)
            assertEqual(entries.first?.entityID, wh.id)
        }

        await test("Audit: stock movement produces entry") {
            let store = makeTempStore()
            let s = makeServices(store)
            let auditRepo = FileAuditRepository(store: store)
            let wh = try await s.warehouseService.createWarehouse(name: "WH", code: "WH-001", address: "", capacity: 100)
            let item = try await s.inventoryService.createItem(sku: "SKU-001", name: "Widget", description: "", category: "", unitOfMeasure: "units", currentQuantity: 100, minimumThreshold: 0, unitCost: 1.0, warehouseID: wh.id)
            _ = try await s.inventoryService.recordMovement(itemID: item.id, type: .stockIn, quantity: 10, note: nil, referenceNumber: nil)
            let entries = try await auditRepo.fetchAll(entityType: "StockMovement", startDate: nil, endDate: nil, action: nil)
            assertEqual(entries.count, 1)
        }

        // Results
        print("\n" + String(repeating: "=", count: 50))
        print("RESULTS: \(passed) passed, \(failed) failed")
        if !errors.isEmpty {
            print("\nFailed tests:")
            errors.forEach { print("  \($0)") }
        }
        print(String(repeating: "=", count: 50))

        if failed > 0 {
            exit(1)
        }
    }
}
