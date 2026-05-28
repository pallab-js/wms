import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class EmployeeServiceTests: XCTestCase {
    private func makeSUT() -> (EmployeeService, MockEmployeeRepository) {
        let repo = MockEmployeeRepository()
        let auditRepo = MockAuditRepository()
        let auditLogger = AuditLogger(repository: auditRepo)
        let service = EmployeeService(repository: repo, auditLogger: auditLogger)
        return (service, repo)
    }

    func testCreateEmployee_validInput_succeeds() async throws {
        let (service, repo) = makeSUT()

        let employee = try await service.createEmployee(
            firstName: "John",
            lastName: "Doe",
            employeeCode: "EMP-001",
            jobTitle: "Manager",
            email: "john@example.com",
            phone: "555-1234",
            hireDate: Date(),
            notes: ""
        )

        XCTAssertEqual(employee.firstName, "John")
        XCTAssertEqual(employee.lastName, "Doe")
        XCTAssertEqual(employee.fullName, "John Doe")
        XCTAssertEqual(employee.employeeCode, "EMP-001")
        XCTAssertEqual(repo.employees.count, 1)
    }

    func testCreateEmployee_duplicateCode_throws() async throws {
        let (service, repo) = makeSUT()
        repo.employees = [Employee(
            firstName: "Jane",
            lastName: "Smith",
            employeeCode: "EMP-001",
            jobTitle: "Clerk",
            email: "jane@example.com"
        )]

        do {
            _ = try await service.createEmployee(
                firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
                jobTitle: "Manager", email: "john@example.com", phone: "",
                hireDate: Date(), notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .duplicateEmployeeCode("EMP-001"))
        }
    }

    func testCreateEmployee_emptyFirstName_throws() async throws {
        let (service, _) = makeSUT()

        do {
            _ = try await service.createEmployee(
                firstName: "", lastName: "Doe", employeeCode: "EMP-001",
                jobTitle: "Manager", email: "john@example.com", phone: "",
                hireDate: Date(), notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("First name cannot be empty."))
        }
    }

    func testCreateEmployee_emptyLastName_throws() async throws {
        let (service, _) = makeSUT()

        do {
            _ = try await service.createEmployee(
                firstName: "John", lastName: "", employeeCode: "EMP-001",
                jobTitle: "Manager", email: "john@example.com", phone: "",
                hireDate: Date(), notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Last name cannot be empty."))
        }
    }

    func testCreateEmployee_emptyEmail_throws() async throws {
        let (service, _) = makeSUT()

        do {
            _ = try await service.createEmployee(
                firstName: "John", lastName: "Doe", employeeCode: "EMP-001",
                jobTitle: "Manager", email: "", phone: "",
                hireDate: Date(), notes: ""
            )
            XCTFail("Expected error")
        } catch let error as WMSError {
            XCTAssertEqual(error, .validationError("Email cannot be empty."))
        }
    }

    func testGetEmployee_notFound_throws() async throws {
        let (service, _) = makeSUT()

        do {
            _ = try await service.getEmployee(byID: UUID())
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is WMSError)
        }
    }

    func testGetEmployees_forWarehouse_filtersCorrectly() async throws {
        let (service, repo) = makeSUT()
        let warehouseA = UUID()
        let warehouseB = UUID()
        repo.employees = [
            Employee(firstName: "A", lastName: "1", employeeCode: "E-001", jobTitle: "", email: "a@x.com", warehouseIDs: [warehouseA]),
            Employee(firstName: "B", lastName: "2", employeeCode: "E-002", jobTitle: "", email: "b@x.com", warehouseIDs: [warehouseB]),
            Employee(firstName: "C", lastName: "3", employeeCode: "E-003", jobTitle: "", email: "c@x.com", warehouseIDs: [warehouseA, warehouseB]),
        ]

        let result = try await service.getEmployees(forWarehouseID: warehouseA)

        XCTAssertEqual(result.count, 2)
    }

    func testDeactivateEmployee_setsIsActiveFalse() async throws {
        let (service, repo) = makeSUT()
        let id = UUID()
        repo.employees = [Employee(
            id: id, firstName: "John", lastName: "Doe",
            employeeCode: "EMP-001", jobTitle: "Manager",
            email: "john@example.com", isActive: true
        )]

        try await service.deactivateEmployee(id: id)

        XCTAssertFalse(repo.employees.first?.isActive ?? true)
    }

    func testDeleteEmployee_succeeds() async throws {
        let (service, repo) = makeSUT()
        let id = UUID()
        repo.employees = [Employee(
            id: id, firstName: "John", lastName: "Doe",
            employeeCode: "EMP-001", jobTitle: "Manager",
            email: "john@example.com"
        )]

        try await service.deleteEmployee(id: id)

        XCTAssertTrue(repo.employees.isEmpty)
    }

    func testUpdateEmployee_succeeds() async throws {
        let (service, repo) = makeSUT()
        var employee = Employee(
            firstName: "John", lastName: "Doe",
            employeeCode: "EMP-001", jobTitle: "Manager",
            email: "john@example.com"
        )
        repo.employees = [employee]

        employee.jobTitle = "Director"
        try await service.updateEmployee(employee)

        XCTAssertEqual(repo.employees.first?.jobTitle, "Director")
    }
}
