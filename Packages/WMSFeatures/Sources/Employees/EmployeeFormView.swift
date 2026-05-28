import SwiftUI
import WMSCore
import WMSDesignSystem

public struct EmployeeFormView: View {
    let title: String
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var employeeCode: String
    @Binding var jobTitle: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var hireDate: Date
    @Binding var notes: String
    let onSave: () -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.wmsTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Form {
                TextField("First Name", text: $firstName)
                    .accessibilityLabel("Employee first name")
                TextField("Last Name", text: $lastName)
                    .accessibilityLabel("Employee last name")
                TextField("Employee Code (e.g. EMP-001)", text: $employeeCode)
                    .accessibilityLabel("Employee code")
                TextField("Job Title", text: $jobTitle)
                    .accessibilityLabel("Job title")
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .accessibilityLabel("Email address")
                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                    .accessibilityLabel("Phone number")
                DatePicker("Hire Date", selection: $hireDate, displayedComponents: .date)
                    .accessibilityLabel("Hire date")
                TextField("Notes", text: $notes)
                    .lineLimit(3)
                    .accessibilityLabel("Additional notes")
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                    .accessibilityLabel("Cancel employee form")
                Button("Save") { onSave() }
                    .disabled(firstName.isEmpty || lastName.isEmpty || employeeCode.isEmpty || email.isEmpty)
                    .accessibilityLabel("Save employee")
                    .accessibilityHint(firstName.isEmpty || lastName.isEmpty ? "First and last name are required" : "Double tap to save")
            }
        }
        .padding()
        .frame(width: 420, height: 480)
    }
}
