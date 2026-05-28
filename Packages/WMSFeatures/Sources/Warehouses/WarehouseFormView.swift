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

    public var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.wmsTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Form {
                TextField("Warehouse Name", text: $name)
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
                    onCancel()
                }
                .accessibilityLabel("Cancel warehouse form")
                Button("Save") {
                    onSave()
                }
                .disabled(name.isEmpty || code.isEmpty)
                .accessibilityLabel("Save warehouse")
                .accessibilityHint(name.isEmpty || code.isEmpty ? "Name and code are required" : "Double tap to save")
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
}
