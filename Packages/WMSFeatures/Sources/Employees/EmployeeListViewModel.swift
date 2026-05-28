import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class EmployeeListViewModel {
    var employees: [Employee] = []
    var isLoading = false
    var errorMessage: String?
    var validationErrors: [String] = []

    private let service: EmployeeService

    public init(service: EmployeeService) {
        self.service = service
    }

    public func loadEmployees() async {
        isLoading = true
        errorMessage = nil
        do {
            employees = try await service.getAllEmployees()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func validateEmployeeForm(
        firstName: String, lastName: String, employeeCode: String, email: String
    ) -> Bool {
        let result = InputValidator.validateEmployeeForm(
            firstName: firstName, lastName: lastName, employeeCode: employeeCode, email: email
        )
        validationErrors = result.errors
        return result.isValid
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
    ) async {
        do {
            _ = try await service.createEmployee(
                firstName: firstName, lastName: lastName,
                employeeCode: employeeCode, jobTitle: jobTitle,
                email: email, phone: phone,
                hireDate: hireDate, notes: notes
            )
            await loadEmployees()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateEmployee(_ employee: Employee) async {
        do {
            try await service.updateEmployee(employee)
            await loadEmployees()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deactivateEmployee(id: UUID) async {
        do {
            try await service.deactivateEmployee(id: id)
            await loadEmployees()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteEmployee(id: UUID) async {
        do {
            try await service.deleteEmployee(id: id)
            await loadEmployees()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
