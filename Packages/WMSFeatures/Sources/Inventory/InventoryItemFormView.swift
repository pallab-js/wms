import SwiftUI
import WMSCore
import WMSDesignSystem

public struct InventoryItemFormView: View {
    let title: String
    let warehouses: [Warehouse]
    @Binding var sku: String
    @Binding var name: String
    @Binding var description: String
    @Binding var category: String
    @Binding var unitOfMeasure: String
    @Binding var currentQuantity: String
    @Binding var minimumThreshold: String
    @Binding var unitCost: String
    @Binding var selectedWarehouseID: UUID?
    let onSave: () -> Void
    let onCancel: () -> Void

    public var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.wmsTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Form {
                TextField("SKU", text: $sku)
                    .accessibilityLabel("Stock keeping unit code")
                TextField("Item Name", text: $name)
                    .accessibilityLabel("Item name")
                TextField("Description", text: $description)
                    .accessibilityLabel("Item description")
                TextField("Category", text: $category)
                    .accessibilityLabel("Item category")

                Picker("Unit of Measure", selection: $unitOfMeasure) {
                    Text("units").tag("units")
                    Text("kg").tag("kg")
                    Text("litres").tag("litres")
                    Text("boxes").tag("boxes")
                    Text("pallets").tag("pallets")
                }
                .accessibilityLabel("Unit of measure")

                TextField("Quantity", text: $currentQuantity)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Current quantity")
                TextField("Min Threshold", text: $minimumThreshold)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Minimum threshold for low stock alert")
                TextField("Unit Cost ($)", text: $unitCost)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Unit cost in dollars")

                Picker("Warehouse", selection: $selectedWarehouseID) {
                    Text("Select Warehouse").tag(nil as UUID?)
                    ForEach(warehouses) { wh in
                        Text("\(wh.name) (\(wh.code))").tag(wh.id as UUID?)
                    }
                }
                .accessibilityLabel("Assign to warehouse")
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { onCancel() }
                    .accessibilityLabel("Cancel item form")
                Button("Save") { onSave() }
                    .disabled(sku.isEmpty || name.isEmpty || selectedWarehouseID == nil)
                    .accessibilityLabel("Save inventory item")
                    .accessibilityHint(sku.isEmpty || name.isEmpty ? "SKU and name are required" : "Double tap to save")
            }
        }
        .padding()
        .frame(width: 420, height: 520)
    }
}
