import SwiftUI
import WMSCore
import WMSDesignSystem

public struct WarehouseFormView: View {
    let title: String
    @Binding var name: String
    @Binding var code: String
    @Binding var address: String
    @Binding var capacity: String
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var validationErrors: [String] = []

    public var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.wmsTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !validationErrors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(validationErrors, id: \.self) { error in
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.wmsDestructive)
                                .font(.caption)
                            Text(error)
                                .font(.wmsCaption)
                                .foregroundColor(.wmsDestructive)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.wmsDestructive.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Form {
                TextField("Warehouse Name", text: $name)
                    .overlay(alignment: .trailing) {
                        if name.isEmpty && !validationErrors.isEmpty {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.wmsDestructive)
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("Warehouse name")
                TextField("Code (e.g. WH-001)", text: $code)
                    .accessibilityLabel("Warehouse code")
                TextField("Address", text: $address)
                    .accessibilityLabel("Warehouse address")
                TextField("Capacity (units)", text: $capacity)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Warehouse capacity in units")
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    validationErrors = []
                    onCancel()
                }
                .accessibilityLabel("Cancel warehouse form")
                .keyboardShortcut(.escape)
                Button("Save") {
                    let result = InputValidator.validateWarehouseForm(
                        name: name, code: code, address: address, capacity: capacity
                    )
                    if result.isValid {
                        validationErrors = []
                        onSave()
                    } else {
                        validationErrors = result.errors
                    }
                }
                .disabled(name.isEmpty || code.isEmpty)
                .accessibilityLabel("Save warehouse")
                .accessibilityHint(name.isEmpty || code.isEmpty ? "Name and code are required" : "Double tap to save")
            }
        }
        .padding()
        .frame(width: 400, height: 340)
    }
}
