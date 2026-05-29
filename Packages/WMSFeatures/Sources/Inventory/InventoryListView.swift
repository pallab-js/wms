import SwiftUI
import WMSCore
import WMSDesignSystem

public struct InventoryListView: View {
    @Bindable var viewModel: InventoryListViewModel
    @Binding var warehouses: [Warehouse]

    @State private var showCreateSheet = false
    @State private var editingItem: InventoryItem?
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: InventoryItem?
    @State private var stockMovementItem: InventoryItem?

    @State private var sku = ""
    @State private var name = ""
    @State private var description = ""
    @State private var category = ""
    @State private var unitOfMeasure = "units"
    @State private var currentQuantity = ""
    @State private var minimumThreshold = ""
    @State private var unitCost = ""
    @State private var selectedWarehouseID: UUID?
    @State private var showSuccessToast = false
    @State private var successMessage = ""
    @State private var showNoWarehouseAlert = false

    public init(viewModel: InventoryListViewModel, warehouses: Binding<[Warehouse]>) {
        self.viewModel = viewModel
        self._warehouses = warehouses
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                WMSLoadingView(message: "Loading inventory...")
            } else if viewModel.items.isEmpty {
                ContentUnavailableView(
                    "No Inventory Items",
                    systemImage: "shippingbox",
                    description: Text("Add inventory items to get started.")
                )
            } else {
                Table(viewModel.items) {
                    TableColumn("SKU") { item in
                        Text(item.sku)
                            .font(.wmsMonospace)
                    }
                    .width(min: 80, max: 120)

                    TableColumn("Name") { item in
                        Text(item.name)
                            .font(.wmsBody)
                    }

                    TableColumn("Category") { item in
                        Text(item.category)
                            .font(.wmsCaption)
                            .foregroundColor(.wmsTextSecondary)
                    }
                    .width(min: 80, max: 150)

                    TableColumn("Qty") { item in
                        HStack(spacing: 4) {
                            Text("\(item.currentQuantity)")
                                .font(.wmsMonospace)
                                .foregroundColor(item.currentQuantity <= item.minimumThreshold ? .wmsWarning : .wmsTextPrimary)
                            if item.currentQuantity <= item.minimumThreshold {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.wmsWarning)
                            }
                        }
                    }
                    .width(70)

                    TableColumn("Unit Cost") { item in
                        Text(item.unitCost, format: .currency(code: "USD"))
                            .font(.wmsMonospace)
                    }
                    .width(80)
                }
                .contextMenu(forSelectionType: InventoryItem.ID.self) { itemIDs in
                    if let itemID = itemIDs.first,
                       let item = viewModel.items.first(where: { $0.id == itemID }) {
                        Button("Record Stock Movement") { stockMovementItem = item }
                        Button("Edit") { beginEditing(item) }
                        Divider()
                        Button("Delete", role: .destructive) {
                            itemToDelete = item
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    guard !warehouses.isEmpty else {
                        showNoWarehouseAlert = true
                        return
                    }
                    resetForm()
                    selectedWarehouseID = warehouses.first?.id
                    showCreateSheet = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .keyboardShortcut("n")
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            InventoryItemFormView(
                title: "New Item",
                warehouses: warehouses,
                sku: $sku, name: $name, description: $description,
                category: $category, unitOfMeasure: $unitOfMeasure,
                currentQuantity: $currentQuantity, minimumThreshold: $minimumThreshold,
                unitCost: $unitCost, selectedWarehouseID: $selectedWarehouseID,
                onSave: {
                    Task {
                        await viewModel.createItem(
                            sku: sku, name: name, description: description,
                            category: category, unitOfMeasure: unitOfMeasure,
                            currentQuantity: Int(currentQuantity) ?? 0,
                            minimumThreshold: Int(minimumThreshold) ?? 0,
                            unitCost: Double(unitCost) ?? 0,
                            warehouseID: selectedWarehouseID ?? warehouses.first?.id ?? UUID()
                        )
                        showCreateSheet = false
                        if viewModel.errorMessage == nil {
                            successMessage = "Item created"
                            showSuccessToast = true
                        }
                    }
                },
                onCancel: { showCreateSheet = false }
            )
        }
        .sheet(item: $editingItem) { item in
            InventoryItemFormView(
                title: "Edit Item",
                warehouses: warehouses,
                sku: $sku, name: $name, description: $description,
                category: $category, unitOfMeasure: $unitOfMeasure,
                currentQuantity: $currentQuantity, minimumThreshold: $minimumThreshold,
                unitCost: $unitCost, selectedWarehouseID: $selectedWarehouseID,
                onSave: {
                    Task {
                        var updated = item
                        updated.sku = sku
                        updated.name = name
                        updated.description = description
                        updated.category = category
                        updated.unitOfMeasure = unitOfMeasure
                        updated.currentQuantity = Int(currentQuantity) ?? 0
                        updated.minimumThreshold = Int(minimumThreshold) ?? 0
                        updated.unitCost = Double(unitCost) ?? 0
                        updated.warehouseID = selectedWarehouseID ?? item.warehouseID
                        updated.updatedAt = Date()
                        await viewModel.updateItem(updated)
                        editingItem = nil
                        if viewModel.errorMessage == nil {
                            successMessage = "Item updated"
                            showSuccessToast = true
                        }
                    }
                },
                onCancel: { editingItem = nil }
            )
        }
        .sheet(item: $stockMovementItem) { item in
            StockMovementView(viewModel: viewModel, item: item)
        }
        .alert("No Warehouses", isPresented: $showNoWarehouseAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Create a warehouse first before adding inventory items.")
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let id = itemToDelete?.id {
                    Task { await viewModel.deleteItem(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(itemToDelete?.name ?? "this item").")
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

    private func beginEditing(_ item: InventoryItem) {
        sku = item.sku
        name = item.name
        description = item.description
        category = item.category
        unitOfMeasure = item.unitOfMeasure
        currentQuantity = "\(item.currentQuantity)"
        minimumThreshold = "\(item.minimumThreshold)"
        unitCost = "\(item.unitCost)"
        selectedWarehouseID = item.warehouseID
        editingItem = item
    }

    private func resetForm() {
        sku = ""
        name = ""
        description = ""
        category = ""
        unitOfMeasure = "units"
        currentQuantity = ""
        minimumThreshold = ""
        unitCost = ""
        selectedWarehouseID = warehouses.first?.id
    }
}
