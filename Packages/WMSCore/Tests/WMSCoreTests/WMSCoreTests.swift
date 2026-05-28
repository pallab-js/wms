import XCTest
@testable import WMSCore

final class WMSCoreTests: XCTestCase {
    func testWarehouse_init_setsPropertiesCorrectly() {
        let warehouse = Warehouse(
            name: "Main Warehouse",
            code: "WH-001",
            address: "123 Main St",
            capacity: 1000
        )

        XCTAssertEqual(warehouse.name, "Main Warehouse")
        XCTAssertEqual(warehouse.code, "WH-001")
        XCTAssertEqual(warehouse.address, "123 Main St")
        XCTAssertEqual(warehouse.capacity, 1000)
        XCTAssertTrue(warehouse.isActive)
    }

    func testWarehouse_equality_worksCorrectly() {
        let id = UUID()
        let w1 = Warehouse(id: id, name: "A", code: "WH-001", address: "", capacity: 100)
        let w2 = Warehouse(id: id, name: "B", code: "WH-002", address: "", capacity: 200)

        XCTAssertEqual(w1, w2)
    }

    func testInventoryItem_init_setsDefaultValues() {
        let item = InventoryItem(
            sku: "SKU-001",
            name: "Test Item",
            warehouseID: UUID()
        )

        XCTAssertEqual(item.sku, "SKU-001")
        XCTAssertEqual(item.currentQuantity, 0)
        XCTAssertEqual(item.minimumThreshold, 0)
        XCTAssertTrue(item.isActive)
    }

    func testStockMovement_movementType_rawValues() {
        XCTAssertEqual(MovementType.stockIn.rawValue, "stockIn")
        XCTAssertEqual(MovementType.stockOut.rawValue, "stockOut")
        XCTAssertEqual(MovementType.adjustment.rawValue, "adjustment")
    }

    func testUserRole_administrator_hasAllPermissions() {
        let permissions = UserRole.administrator.permissions
        XCTAssertEqual(permissions.count, Permission.allCases.count)
    }

    func testUserRole_analyst_hasLimitedPermissions() {
        let permissions = UserRole.analyst.permissions
        XCTAssertTrue(permissions.contains(.viewReports))
        XCTAssertTrue(permissions.contains(.exportData))
        XCTAssertFalse(permissions.contains(.createWarehouse))
        XCTAssertFalse(permissions.contains(.recordStockIn))
    }

    func testWMSError_errorDescription_returnsCorrectMessages() {
        let error = WMSError.duplicateWarehouseCode("WH-001")
        XCTAssertTrue(error.errorDescription?.contains("WH-001") == true)
    }

    func testWMSError_recoverySuggestion_returnsAdvice() {
        let error = WMSError.insufficientStock(itemName: "Widget", available: 5, requested: 10)
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testTransferOrder_status_transitions() {
        var order = TransferOrder(
            transferCode: "TR-001",
            sourceWarehouseID: UUID(),
            destinationWarehouseID: UUID()
        )
        XCTAssertEqual(order.status, .draft)

        order.status = .submitted
        XCTAssertEqual(order.status, .submitted)

        order.status = .approved
        XCTAssertEqual(order.status, .approved)
    }

    func testEmployee_fullName_concatenatesNames() {
        let employee = Employee(
            firstName: "John",
            lastName: "Doe",
            employeeCode: "EMP-001",
            jobTitle: "Manager",
            email: "john@example.com"
        )

        XCTAssertEqual(employee.fullName, "John Doe")
    }

    func testAlertRecord_severity_values() {
        XCTAssertEqual(AlertSeverity.info.rawValue, "info")
        XCTAssertEqual(AlertSeverity.warning.rawValue, "warning")
        XCTAssertEqual(AlertSeverity.critical.rawValue, "critical")
    }

    func testPaginatedResult_totalPages() {
        let result = PaginatedResult(items: [1, 2, 3], totalCount: 10, page: 0, pageSize: 3)
        XCTAssertEqual(result.totalPages, 4)
        XCTAssertTrue(result.hasNextPage)
        XCTAssertFalse(result.hasPreviousPage)
    }

    func testPaginatedResult_lastPage() {
        let result = PaginatedResult(items: [10], totalCount: 10, page: 3, pageSize: 3)
        XCTAssertFalse(result.hasNextPage)
        XCTAssertTrue(result.hasPreviousPage)
    }

    func testPaginatedResult_emptyResult() {
        let result = PaginatedResult<String>(items: [], totalCount: 0, page: 0, pageSize: 10)
        XCTAssertEqual(result.totalPages, 0)
        XCTAssertFalse(result.hasNextPage)
        XCTAssertFalse(result.hasPreviousPage)
    }

    func testInputValidator_validateNotEmpty_succeeds() {
        let result = InputValidator.validateNotEmpty("Hello", field: "Name")
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testInputValidator_validateNotEmpty_fails() {
        let result = InputValidator.validateNotEmpty("", field: "Name")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errors.count, 1)
    }

    func testInputValidator_validatePositiveInt_succeeds() {
        let result = InputValidator.validatePositiveInt("42", field: "Quantity")
        XCTAssertTrue(result.isValid)
    }

    func testInputValidator_validatePositiveInt_failsOnZero() {
        let result = InputValidator.validatePositiveInt("0", field: "Quantity")
        XCTAssertFalse(result.isValid)
    }

    func testInputValidator_validatePositiveInt_failsOnNonNumeric() {
        let result = InputValidator.validatePositiveInt("abc", field: "Quantity")
        XCTAssertFalse(result.isValid)
    }

    func testInputValidator_validateWarehouseForm_succeeds() {
        let result = InputValidator.validateWarehouseForm(
            name: "Main", code: "WH-001", address: "123 St", capacity: "500"
        )
        XCTAssertTrue(result.isValid)
    }

    func testInputValidator_validateWarehouseForm_failsOnEmptyName() {
        let result = InputValidator.validateWarehouseForm(
            name: "", code: "WH-001", address: "123 St", capacity: "500"
        )
        XCTAssertFalse(result.isValid)
        XCTAssertFalse(result.errors.isEmpty)
    }

    func testInputValidator_validateWarehouseForm_failsOnInvalidCapacity() {
        let result = InputValidator.validateWarehouseForm(
            name: "Main", code: "WH-001", address: "123 St", capacity: "-5"
        )
        XCTAssertFalse(result.isValid)
    }

    func testInputValidator_validateEmployeeForm_succeeds() {
        let result = InputValidator.validateEmployeeForm(
            firstName: "John", lastName: "Doe", employeeCode: "EMP-001", email: "john@example.com"
        )
        XCTAssertTrue(result.isValid)
    }

    func testInputValidator_validateEmployeeForm_failsOnMultipleFields() {
        let result = InputValidator.validateEmployeeForm(
            firstName: "", lastName: "", employeeCode: "", email: ""
        )
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errors.count, 4)
    }
}
