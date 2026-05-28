import SwiftUI
import WMSCore
import WMSDesignSystem

public struct TransferFormView: View {
    let viewModel: TransferListViewModel
    let warehouses: [Warehouse]
    let inventoryItems: [InventoryItem]

    @State private var sourceWarehouseID: UUID?
    @State private var destinationWarehouseID: UUID?
    @State private var notes = ""
    @State private var lineItems: [DraftLineItem] = [DraftLineItem()]
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: TransferListViewModel, warehouses: [Warehouse], inventoryItems: [InventoryItem]) {
        self.viewModel = viewModel
        self.warehouses = warehouses
        self.inventoryItems = inventoryItems
    }

    private var sourceWarehouseItems: [InventoryItem] {
        guard let sourceID = sourceWarehouseID else { return [] }
        return inventoryItems.filter { $0.warehouseID == sourceID && $0.currentQuantity > 0 }
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("New Transfer Order")
                .font(.wmsTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Form {
                Picker("Source Warehouse", selection: $sourceWarehouseID) {
                    Text("Select Source").tag(nil as UUID?)
                    ForEach(warehouses) { wh in
                        Text("\(wh.name) (\(wh.code))").tag(wh.id as UUID?)
                    }
                }
                .onChange(of: sourceWarehouseID) {
                    destinationWarehouseID = nil
                    lineItems = [DraftLineItem()]
                }

                Picker("Destination Warehouse", selection: $destinationWarehouseID) {
                    Text("Select Destination").tag(nil as UUID?)
                    ForEach(warehouses.filter { $0.id != sourceWarehouseID }) { wh in
                        Text("\(wh.name) (\(wh.code))").tag(wh.id as UUID?)
                    }
                }

                Section("Line Items") {
                    ForEach($lineItems) { $item in
                        HStack {
                            Picker("Item", selection: $item.selectedItemID) {
                                Text("Select Item").tag(nil as UUID?)
                                ForEach(sourceWarehouseItems) { inv in
                                    Text("\(inv.name) (\(inv.sku)) — \(inv.currentQuantity) in stock")
                                        .tag(inv.id as UUID?)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)

                            TextField("Qty", text: $item.quantity)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)

                            Button { removeLineItem(item) } label: {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.wmsDestructive)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        lineItems.append(DraftLineItem())
                    } label: {
                        Label("Add Line Item", systemImage: "plus")
                    }
                    .disabled(sourceWarehouseItems.isEmpty)
                }

                Section("Notes") {
                    TextField("Transfer notes (optional)", text: $notes)
                        .lineLimit(2)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button("Create Transfer") {
                    Task {
                        guard let source = sourceWarehouseID,
                              let dest = destinationWarehouseID,
                              source != dest else { return }

                        let items = lineItems.compactMap { item -> TransferLineItem? in
                            guard let itemID = item.selectedItemID,
                                  let qty = Int(item.quantity), qty > 0 else { return nil }
                            return TransferLineItem(
                                inventoryItemID: itemID,
                                requestedQuantity: qty
                            )
                        }

                        guard !items.isEmpty else { return }

                        await viewModel.createTransfer(
                            sourceWarehouseID: source,
                            destinationWarehouseID: dest,
                            lineItems: items,
                            notes: notes
                        )
                        dismiss()
                    }
                }
                .disabled(
                    sourceWarehouseID == nil ||
                    destinationWarehouseID == nil ||
                    sourceWarehouseID == destinationWarehouseID ||
                    lineItems.allSatisfy { $0.selectedItemID == nil || (Int($0.quantity) ?? 0) <= 0 }
                )
            }
        }
        .padding()
        .frame(width: 520, height: 560)
    }

    private func removeLineItem(_ item: DraftLineItem) {
        lineItems.removeAll { $0.id == item.id }
        if lineItems.isEmpty { lineItems.append(DraftLineItem()) }
    }
}

struct DraftLineItem: Identifiable {
    let id = UUID()
    var selectedItemID: UUID?
    var quantity = ""
}
