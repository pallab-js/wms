import SwiftUI
import WMSCore
import WMSDesignSystem

public struct WarehouseListView: View {
    @Bindable var viewModel: WarehouseListViewModel
    @State private var showCreateSheet = false
    @State private var editingWarehouse: Warehouse?
    @State private var showDeleteConfirmation = false
    @State private var warehouseToDelete: Warehouse?

    @State private var newName = ""
    @State private var newCode = ""
    @State private var newAddress = ""
    @State private var newCapacity = ""
    @State private var showSuccessToast = false
    @State private var successMessage = ""

    public init(viewModel: WarehouseListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                WMSLoadingView(message: "Loading warehouses...")
            } else if viewModel.warehouses.isEmpty {
                ContentUnavailableView(
                    "No Warehouses",
                    systemImage: "building.2",
                    description: Text("Add your first warehouse to get started.")
                )
            } else {
                List(viewModel.warehouses) { warehouse in
                    NavigationLink(value: warehouse) {
                        WarehouseRowView(warehouse: warehouse)
                    }
                    .contextMenu {
                        Button("Edit") { beginEditing(warehouse) }
                        Divider()
                        Button("Delete", role: .destructive) {
                            warehouseToDelete = warehouse
                            showDeleteConfirmation = true
                        }
                    }
                }
                .listStyle(.sidebar)
                .navigationDestination(for: Warehouse.self) { warehouse in
                    WarehouseDetailView(warehouse: warehouse) { updated in
                        Task { await viewModel.updateWarehouse(updated) }
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
                    Label("Add Warehouse", systemImage: "plus")
                        .keyboardShortcut("n")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            WarehouseFormView(
                title: "New Warehouse",
                name: $newName,
                code: $newCode,
                address: $newAddress,
                capacity: $newCapacity,
                onSave: {
                    Task {
                        await viewModel.createWarehouse(
                            name: newName, code: newCode,
                            address: newAddress, capacity: Int(newCapacity) ?? 0
                        )
                        showCreateSheet = false
                        if viewModel.errorMessage == nil {
                            successMessage = "Warehouse created"
                            showSuccessToast = true
                        }
                    }
                },
                onCancel: { showCreateSheet = false }
            )
        }
        .sheet(item: $editingWarehouse) { warehouse in
            WarehouseFormView(
                title: "Edit Warehouse",
                name: $newName,
                code: $newCode,
                address: $newAddress,
                capacity: $newCapacity,
                onSave: {
                    Task {
                        var updated = warehouse
                        updated.name = newName
                        updated.code = newCode
                        updated.address = newAddress
                        updated.capacity = Int(newCapacity) ?? 0
                        updated.updatedAt = Date()
                        await viewModel.updateWarehouse(updated)
                        editingWarehouse = nil
                        if viewModel.errorMessage == nil {
                            successMessage = "Warehouse updated"
                            showSuccessToast = true
                        }
                    }
                },
                onCancel: { editingWarehouse = nil }
            )
        }
        .alert("Delete Warehouse?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let id = warehouseToDelete?.id {
                    Task { await viewModel.deleteWarehouse(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(warehouseToDelete?.name ?? "this warehouse") and all its data.")
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

    private func beginEditing(_ warehouse: Warehouse) {
        newName = warehouse.name
        newCode = warehouse.code
        newAddress = warehouse.address
        newCapacity = "\(warehouse.capacity)"
        editingWarehouse = warehouse
    }

    private func resetForm() {
        newName = ""
        newCode = ""
        newAddress = ""
        newCapacity = ""
    }
}

public struct WarehouseRowView: View {
    let warehouse: Warehouse

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(warehouse.name)
                    .font(.wmsHeadline)
                Text(warehouse.code)
                    .font(.wmsMonospaceCaption)
                    .foregroundColor(.wmsTextSecondary)
            }
            Spacer()
            if !warehouse.isActive {
                WMSBadge(text: "Inactive", color: .wmsTextSecondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(warehouse.name), \(warehouse.code)\(warehouse.isActive ? "" : ", inactive")")
    }
}
