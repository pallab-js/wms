import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class WarehouseServiceTests: XCTestCase {
    func testCreateWarehouse_validInput_succeeds() async throws {
        let repo = MockWarehouseRepository()
        let service = WarehouseService(repository: repo)

        let warehouse = try await service.createWarehouse(
            name: "Test Warehouse",
            code: "WH-001",
            address: "123 Main St",
            capacity: 500
        )

        XCTAssertEqual(warehouse.name, "Test Warehouse")
        XCTAssertEqual(warehouse.code, "WH-001")
        XCTAssertEqual(repo.warehouses.count, 1)
    }

    func testCreateWarehouse_duplicateCode_throws() async throws {
        let repo = MockWarehouseRepository()
        repo.warehouses = [Warehouse(name: "Existing", code: "WH-001", address: "", capacity: 100)]
        let service = WarehouseService(repository: repo)

        do {
            _ = try await service.createWarehouse(name: "New", code: "WH-001", address: "", capacity: 100)
            XCTFail("Expected error to be thrown")
        } catch let error as WMSError {
            XCTAssertEqual(error, .duplicateWarehouseCode("WH-001"))
        }
    }

    func testCreateWarehouse_emptyName_throws() async throws {
        let repo = MockWarehouseRepository()
        let service = WarehouseService(repository: repo)

        do {
            _ = try await service.createWarehouse(name: "", code: "WH-001", address: "", capacity: 100)
            XCTFail("Expected error to be thrown")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Name cannot be empty."))
        }
    }

    func testCreateWarehouse_zeroCapacity_throws() async throws {
        let repo = MockWarehouseRepository()
        let service = WarehouseService(repository: repo)

        do {
            _ = try await service.createWarehouse(name: "Test", code: "WH-001", address: "", capacity: 0)
            XCTFail("Expected error to be thrown")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Capacity must be greater than zero."))
        }
    }

    func testGetWarehouse_notFound_throws() async throws {
        let repo = MockWarehouseRepository()
        let service = WarehouseService(repository: repo)

        do {
            _ = try await service.getWarehouse(byID: UUID())
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testDeactivateWarehouse_setsIsActiveFalse() async throws {
        let repo = MockWarehouseRepository()
        let id = UUID()
        repo.warehouses = [Warehouse(id: id, name: "Test", code: "WH-001", address: "", capacity: 100)]
        let service = WarehouseService(repository: repo)

        try await service.deactivateWarehouse(id: id)

        XCTAssertFalse(repo.warehouses.first?.isActive ?? true)
    }

    func testDeleteWarehouse_removesFromRepo() async throws {
        let repo = MockWarehouseRepository()
        let id = UUID()
        repo.warehouses = [Warehouse(id: id, name: "Test", code: "WH-001", address: "", capacity: 100)]
        let service = WarehouseService(repository: repo)

        try await service.deleteWarehouse(id: id)

        XCTAssertTrue(repo.warehouses.isEmpty)
    }

    func testGetTotalWarehouseCount_onlyActive() async throws {
        let repo = MockWarehouseRepository()
        let service = WarehouseService(repository: repo)
        repo.warehouses = [
            Warehouse(name: "A", code: "WH-A", address: "", capacity: 100, isActive: true),
            Warehouse(name: "B", code: "WH-B", address: "", capacity: 100, isActive: false),
        ]

        let count = try await service.getTotalWarehouseCount()

        XCTAssertEqual(count, 1)
    }
}
