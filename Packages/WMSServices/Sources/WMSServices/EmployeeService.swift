import Foundation
import WMSCore

public final class EmployeeService: Sendable {
    private let repository: any EmployeeRepository
    private let auditLogger: any AuditLogging
    private let accessController: any PermissionChecking

    public init(
        repository: any EmployeeRepository,
        auditLogger: any AuditLogging = NullAuditLogger(),
        accessController: any PermissionChecking = NullPermissionChecker()
    ) {
        self.repository = repository
        self.auditLogger = auditLogger
        self.accessController = accessController
    }

    public func getAllEmployees() async throws -> [Employee] {
        try await repository.fetchAll()
    }

    public func getEmployee(byID id: UUID) async throws -> Employee {
        guard let employee = try await repository.fetch(byID: id) else {
            throw WMSError.employeeNotFound
        }
        return employee
    }

    public func getEmployees(forWarehouseID warehouseID: UUID) async throws -> [Employee] {
        try await repository.fetch(byWarehouseID: warehouseID)
    }

    public func createEmployee(
        firstName: String,
        lastName: String,
        employeeCode: String,
        jobTitle: String,
        email: String,
        phone: String,
        hireDate: Date,
        notes: String
    ) async throws -> Employee {
        try accessController.require(.createEmployee)
        try InputValidator.requireNotEmpty(firstName, field: "First name")
        try InputValidator.requireNotEmpty(lastName, field: "Last name")
        try InputValidator.requireNotEmpty(employeeCode, field: "Employee code")
        try InputValidator.requireValidEmail(email)

        let existing = try await repository.fetchAll()
        guard !existing.contains(where: { $0.employeeCode.lowercased() == employeeCode.lowercased() }) else {
            throw WMSError.duplicateEmployeeCode(employeeCode)
        }

        let employee = Employee(
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            employeeCode: employeeCode.trimmingCharacters(in: .whitespacesAndNewlines),
            jobTitle: jobTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
            hireDate: hireDate,
            notes: notes
        )
        try await repository.save(employee)
        await auditLogger.log(entityType: "Employee", entityID: employee.id, action: "created")
        return employee
    }

    public func updateEmployee(_ employee: Employee) async throws {
        try accessController.require(.editEmployee)
        try InputValidator.requireNotEmpty(employee.firstName, field: "First name")
        var updated = employee
        updated.firstName = employee.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.lastName = employee.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.employeeCode = employee.employeeCode.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.email = employee.email.trimmingCharacters(in: .whitespacesAndNewlines)
        try await repository.save(updated)
        await auditLogger.log(entityType: "Employee", entityID: employee.id, action: "updated")
    }

    public func deactivateEmployee(id: UUID) async throws {
        try accessController.require(.deactivateEmployee)
        var employee = try await getEmployee(byID: id)
        employee.isActive = false
        try await repository.save(employee)
        await auditLogger.log(entityType: "Employee", entityID: id, action: "deactivated")
    }

    public func deleteEmployee(id: UUID) async throws {
        try accessController.require(.deleteEmployee)
        try await repository.delete(id: id)
        await auditLogger.log(entityType: "Employee", entityID: id, action: "deleted")
    }
}
