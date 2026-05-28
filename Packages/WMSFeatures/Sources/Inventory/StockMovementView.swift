import SwiftUI
import WMSCore
import WMSDesignSystem

public struct StockMovementView: View {
    let viewModel: InventoryListViewModel
    let item: InventoryItem
    @State private var movementType: MovementType = .stockIn
    @State private var quantity = ""
    @State private var note = ""
    @State private var referenceNumber = ""
    @State private var isRecording = false
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Record Stock Movement")
                        .font(.wmsTitle)
                    Text("\(item.name) — SKU: \(item.sku)")
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextSecondary)
                }
                Spacer()
                Text("Current: \(item.currentQuantity)")
                    .font(.wmsMonospace)
            }

            Divider()

            Picker("Movement Type", selection: $movementType) {
                Text("Stock In").tag(MovementType.stockIn)
                Text("Stock Out").tag(MovementType.stockOut)
                Text("Adjustment").tag(MovementType.adjustment)
            }
            .pickerStyle(.segmented)

            Form {
                TextField("Quantity", text: $quantity)
                    .textFieldStyle(.roundedBorder)
                TextField("Note (optional)", text: $note)
                TextField("Reference Number (optional)", text: $referenceNumber)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Record") {
                    isRecording = true
                }
                .disabled(quantity.isEmpty || Int(quantity) == nil || Int(quantity)! <= 0)
            }
        }
        .padding()
        .frame(width: 400, height: 350)
        .task {
            if isRecording, let qty = Int(quantity), qty > 0 {
                await viewModel.recordMovement(
                    itemID: item.id,
                    type: movementType,
                    quantity: qty,
                    note: note.isEmpty ? nil : note,
                    referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber
                )
                dismiss()
                isRecording = false
            }
        }
    }
}
