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
    @State private var showConfirmation = false
    @Environment(\.dismiss) private var dismiss

    private var quantityValue: Int? {
        guard let qty = Int(quantity), qty > 0 else { return nil }
        return qty
    }

    private var newBalance: Int? {
        guard let qty = quantityValue else { return nil }
        switch movementType {
        case .stockIn: return item.currentQuantity + qty
        case .stockOut: return item.currentQuantity - qty
        case .adjustment: return qty
        }
    }

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
                .keyboardShortcut(.escape)
                Button("Record") {
                    showConfirmation = true
                }
                .disabled(quantityValue == nil)
            }
        }
        .padding()
        .frame(width: 400, height: 380)
        .confirmationDialog(
            "Confirm Stock Movement",
            isPresented: $showConfirmation
        ) {
            Button("Record \(movementTypeLabel)") {
                guard let qty = quantityValue else { return }
                Task {
                    await viewModel.recordMovement(
                        itemID: item.id,
                        type: movementType,
                        quantity: qty,
                        note: note.isEmpty ? nil : note,
                        referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber
                    )
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let balance = newBalance {
                Text("\(movementTypeLabel) \(quantity) units of \(item.name).\nCurrent: \(item.currentQuantity) → New balance: \(balance)")
            } else {
                Text("Record \(movementTypeLabel) for \(item.name)?")
            }
        }
    }

    private var movementTypeLabel: String {
        switch movementType {
        case .stockIn: return "Stock In"
        case .stockOut: return "Stock Out"
        case .adjustment: return "Adjustment"
        }
    }
}
