import SwiftUI
import WMSCore
import WMSDesignSystem

public struct EmployeeListView: View {
    @Bindable var viewModel: EmployeeListViewModel

    @State private var showCreateSheet = false
    @State private var editingEmployee: Employee?
    @State private var showDeleteConfirmation = false
    @State private var employeeToDelete: Employee?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var employeeCode = ""
    @State private var jobTitle = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var hireDate = Date()
    @State private var notes = ""
    @State private var showSuccessToast = false
    @State private var successMessage = ""

    public init(viewModel: EmployeeListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                WMSLoadingView(message: "Loading employees...")
            } else if viewModel.employees.isEmpty {
                ContentUnavailableView(
                    "No Employees",
                    systemImage: "person.2",
                    description: Text("Add employees to get started.")
                )
            } else {
                Table(viewModel.employees) {
                    TableColumn("Code") { employee in
                        Text(employee.employeeCode)
                            .font(.wmsMonospace)
                    }
                    .width(min: 80, max: 120)

                    TableColumn("Name") { employee in
                        Text(employee.fullName)
                            .font(.wmsBody)
                    }

                    TableColumn("Job Title") { employee in
                        Text(employee.jobTitle)
                            .font(.wmsCaption)
                            .foregroundColor(.wmsTextSecondary)
                    }
                    .width(min: 100, max: 200)

                    TableColumn("Email") { employee in
                        Text(employee.email)
                            .font(.wmsCaption)
                            .foregroundColor(.wmsTextSecondary)
                    }
                    .width(min: 120, max: 200)

                    TableColumn("Status") { employee in
                        WMSBadge(
                            text: employee.isActive ? "Active" : "Inactive",
                            color: employee.isActive ? .wmsSuccess : .wmsTextSecondary
                        )
                    }
                    .width(80)
                }
                .contextMenu(forSelectionType: Employee.ID.self) { empIDs in
                    if let empID = empIDs.first,
                       let emp = viewModel.employees.first(where: { $0.id == empID }) {
                        Button("Edit") { beginEditing(emp) }
                        Button(emp.isActive ? "Deactivate" : "Activate") {
                            Task {
                                if emp.isActive {
                                    await viewModel.deactivateEmployee(id: emp.id)
                                } else {
                                    var updated = emp
                                    updated.isActive = true
                                    await viewModel.updateEmployee(updated)
                                }
                            }
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            employeeToDelete = emp
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    resetForm()
                    showCreateSheet = true
                } label: {
                    Label("Add Employee", systemImage: "plus")
                }
                .keyboardShortcut("n")
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            EmployeeFormView(
                title: "New Employee",
                firstName: $firstName, lastName: $lastName,
                employeeCode: $employeeCode, jobTitle: $jobTitle,
                email: $email, phone: $phone,
                hireDate: $hireDate, notes: $notes,
                onSave: {
                    Task {
                        await viewModel.createEmployee(
                            firstName: firstName, lastName: lastName,
                            employeeCode: employeeCode, jobTitle: jobTitle,
                            email: email, phone: phone,
                            hireDate: hireDate, notes: notes
                        )
                        showCreateSheet = false
                        if viewModel.errorMessage == nil {
                            successMessage = "Employee created"
                            showSuccessToast = true
                        }
                    }
                },
                onCancel: { showCreateSheet = false }
            )
        }
        .sheet(item: $editingEmployee) { employee in
            EmployeeFormView(
                title: "Edit Employee",
                firstName: $firstName, lastName: $lastName,
                employeeCode: $employeeCode, jobTitle: $jobTitle,
                email: $email, phone: $phone,
                hireDate: $hireDate, notes: $notes,
                onSave: {
                    Task {
                        var updated = employee
                        updated.firstName = firstName
                        updated.lastName = lastName
                        updated.employeeCode = employeeCode
                        updated.jobTitle = jobTitle
                        updated.email = email
                        updated.phone = phone
                        updated.hireDate = hireDate
                        updated.notes = notes
                        await viewModel.updateEmployee(updated)
                        editingEmployee = nil
                        if viewModel.errorMessage == nil {
                            successMessage = "Employee updated"
                            showSuccessToast = true
                        }
                    }
                },
                onCancel: { editingEmployee = nil }
            )
        }
        .alert("Delete Employee?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let id = employeeToDelete?.id {
                    Task { await viewModel.deleteEmployee(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(employeeToDelete?.fullName ?? "this employee").")
        }
        .overlay(alignment: .top) {
            if let error = viewModel.errorMessage {
                WMSErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
                .padding()
            }
        }
        .wmsToast(isPresented: $showSuccessToast, message: successMessage)
    }

    private func beginEditing(_ emp: Employee) {
        firstName = emp.firstName
        lastName = emp.lastName
        employeeCode = emp.employeeCode
        jobTitle = emp.jobTitle
        email = emp.email
        phone = emp.phone
        hireDate = emp.hireDate
        notes = emp.notes
        editingEmployee = emp
    }

    private func resetForm() {
        firstName = ""
        lastName = ""
        employeeCode = ""
        jobTitle = ""
        email = ""
        phone = ""
        hireDate = Date()
        notes = ""
    }
}
