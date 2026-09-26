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
    @State private var hasAttemptedSave = false

    public init(
        title: String,
        name: Binding<String>,
        code: Binding<String>,
        address: Binding<String>,
        capacity: Binding<String>,
        onSave: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self._name = name
        self._code = code
        self._address = address
        self._capacity = capacity
        self.onSave = onSave
        self.onCancel = onCancel
    }

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
                        if hasFieldError("Name") {
                            errorIcon
                        }
                    }
                    .accessibilityLabel("Warehouse name")
                TextField("Code (e.g. WH-001)", text: $code)
                    .overlay(alignment: .trailing) {
                        if hasFieldError("Code") {
                            errorIcon
                        }
                    }
                    .accessibilityLabel("Warehouse code")
                TextField("Address", text: $address)
                    .accessibilityLabel("Warehouse address")
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        TextField("Capacity (units)", text: $capacity)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityLabel("Warehouse capacity in units")
                        if hasFieldError("Capacity") {
                            errorIcon
                        }
                    }
                    Text("Maximum units of stock this site can hold")
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextTertiary)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    validationErrors = []
                    hasAttemptedSave = false
                    onCancel()
                }
                .accessibilityLabel("Cancel warehouse form")
                .keyboardShortcut(.escape)
                Button("Save") {
                    hasAttemptedSave = true
                    let result = InputValidator.validateWarehouseForm(
                        name: name, code: code, address: address, capacity: capacity
                    )
                    validationErrors = result.errors
                    if result.isValid {
                        onSave()
                    }
                }
                .disabled(name.isEmpty || code.isEmpty)
                .accessibilityLabel("Save warehouse")
                .accessibilityHint(name.isEmpty || code.isEmpty ? "Name and code are required" : "Double tap to save")
            }
        }
        .padding()
        .frame(width: 400, height: 370)
        .onChange(of: name) { revalidateIfNeeded() }
        .onChange(of: code) { revalidateIfNeeded() }
        .onChange(of: address) { revalidateIfNeeded() }
        .onChange(of: capacity) { revalidateIfNeeded() }
    }

    private var errorIcon: some View {
        Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.wmsDestructive)
            .font(.caption)
            .padding(.trailing, 6)
    }

    private func hasFieldError(_ prefix: String) -> Bool {
        hasAttemptedSave && validationErrors.contains { $0.hasPrefix(prefix) }
    }

    private func revalidateIfNeeded() {
        guard hasAttemptedSave else { return }
        revalidate()
    }

    private func revalidate() {
        let result = InputValidator.validateWarehouseForm(
            name: name, code: code, address: address, capacity: capacity
        )
        validationErrors = result.errors
    }
}
