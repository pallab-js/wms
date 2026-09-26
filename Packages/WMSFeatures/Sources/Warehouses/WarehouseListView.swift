import SwiftUI
import WMSCore
import WMSServices
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
                VStack(spacing: 0) {
                    summaryStrip(viewModel.kpi)
                    Divider()
                    if viewModel.filteredWarehouses.isEmpty {
                        ContentUnavailableView {
                            Label("No Matches", systemImage: "magnifyingglass")
                        } description: {
                            Text("No warehouses match the current search or filter.")
                        } actions: {
                            Button("Clear Filters") { viewModel.clearFilters() }
                        }
                    } else {
                        List(viewModel.filteredWarehouses) { warehouse in
                            NavigationLink(value: warehouse) {
                                WarehouseRowView(
                                    warehouse: warehouse,
                                    stats: viewModel.stats(for: warehouse)
                                )
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
                    }
                }
            }
        }
        .searchable(
            text: $viewModel.searchText,
            placement: .toolbar,
            prompt: "Search name or code"
        )
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Picker("Status", selection: $viewModel.statusFilter) {
                    ForEach(WarehouseStatusFilter.allCases) { filter in
                        Text(filter.label).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 210)

                Menu {
                    ForEach(WarehouseSortOrder.allCases) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            if viewModel.sortOrder == order {
                                Label(order.label, systemImage: "checkmark")
                            } else {
                                Text(order.label)
                            }
                        }
                    }
                } label: {
                    Label(viewModel.sortOrder.label, systemImage: "arrow.up.arrow.down")
                }
                .help("Sort warehouses")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    resetForm()
                    showCreateSheet = true
                } label: {
                    Label("Add Warehouse", systemImage: "plus")
                }
                .keyboardShortcut("n")
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
                        guard viewModel.errorMessage == nil else { return }
                        showCreateSheet = false
                        successMessage = "Warehouse created"
                        showSuccessToast = true
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
                        guard viewModel.errorMessage == nil else { return }
                        editingWarehouse = nil
                        successMessage = "Warehouse updated"
                        showSuccessToast = true
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

    private func summaryStrip(_ kpi: WarehouseListViewModel.KPI) -> some View {
        HStack(spacing: 12) {
            WMSStatCard(
                title: "Warehouses",
                value: "\(kpi.warehouseCount)",
                icon: "building.2",
                color: .wmsInfo,
                subtitle: "\(kpi.activeCount) active"
            )
            WMSStatCard(
                title: "Units Stored",
                value: kpi.unitCount.formatted(),
                icon: "shippingbox",
                color: .wmsSuccess,
                subtitle: "On hand"
            )
            WMSStatCard(
                title: "Inventory Value",
                value: kpi.totalValue.formatted(
                    .currency(code: "USD").precision(.fractionLength(0))
                ),
                icon: "dollarsign",
                color: .wmsAccent,
                subtitle: "At unit cost"
            )
            WMSStatCard(
                title: "Avg Utilisation",
                value: "\(Int(kpi.averageUtilisation))%",
                icon: "gauge",
                color: utilisationColor(kpi.averageUtilisation),
                subtitle: "Capacity used"
            )
        }
        .padding(12)
    }

    private func utilisationColor(_ value: Double) -> Color {
        if value > 90 { return .wmsDestructive }
        if value > 75 { return .wmsWarning }
        return .wmsSuccess
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
    var stats: WarehouseStats?

    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(warehouse.name)
                        .font(.wmsHeadline)
                        .foregroundColor(.wmsTextPrimary)
                    if !warehouse.isActive {
                        WMSBadge(text: "Inactive", color: .wmsTextSecondary)
                    }
                }
                Text("\(warehouse.code) · \(stats?.skuCount ?? 0) SKUs · \((stats?.unitCount ?? 0).formatted()) units")
                    .font(.wmsMonospaceCaption)
                    .foregroundColor(.wmsTextSecondary)
                if let stats {
                    HStack(spacing: 8) {
                        ProgressView(value: min(stats.utilisation, 100), total: 100)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 140)
                        Text("\(Int(stats.utilisation))%")
                            .font(.wmsMonospaceCaption)
                            .foregroundColor(utilisationColor(stats.utilisation))
                        Spacer(minLength: 8)
                        Text(stats.totalValue, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .font(.wmsMonospaceCaption)
                            .foregroundColor(.wmsTextSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        var parts = ["\(warehouse.name), \(warehouse.code)"]
        if !warehouse.isActive { parts.append("inactive") }
        if let stats {
            parts.append("\(stats.skuCount) SKUs")
            parts.append("\(stats.unitCount) units")
            parts.append("\(Int(stats.utilisation)) percent utilised")
        }
        return parts.joined(separator: ", ")
    }

    private func utilisationColor(_ value: Double) -> Color {
        if value > 90 { return .wmsDestructive }
        if value > 75 { return .wmsWarning }
        return .wmsSuccess
    }
}
