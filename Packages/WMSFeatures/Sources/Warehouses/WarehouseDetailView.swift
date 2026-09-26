import SwiftUI
import WMSCore
import WMSServices
import WMSDesignSystem

public struct WarehouseDetailView: View {
    @Bindable var viewModel: WarehouseDetailViewModel
    let onSave: (Warehouse) -> Void
    let onChanged: () -> Void
    let onSelectItem: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var showEditSheet = false
    @State private var editName = ""
    @State private var editCode = ""
    @State private var editAddress = ""
    @State private var editCapacity = ""
    @State private var showDeleteConfirmation = false
    @State private var showSuccessToast = false
    @State private var toastMessage = ""

    public init(
        viewModel: WarehouseDetailViewModel,
        onSave: @escaping (Warehouse) -> Void,
        onChanged: @escaping () -> Void,
        onSelectItem: @escaping (UUID) -> Void
    ) {
        self.viewModel = viewModel
        self.onSave = onSave
        self.onChanged = onChanged
        self.onSelectItem = onSelectItem
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let stats = viewModel.stats {
                    statsStrip(stats)
                    capacityCard(stats)
                    chartsRow(stats)
                    if !stats.lowStockItems.isEmpty {
                        lowStockCard(stats)
                    }
                    if !stats.recentMovements.isEmpty {
                        recentActivityCard(stats)
                    }
                } else if viewModel.isLoading {
                    WMSLoadingView(message: "Loading statistics...")
                }

                detailsBox
            }
            .padding()
        }
        .navigationTitle(viewModel.warehouse.name)
        .task { await viewModel.loadStats() }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    editName = viewModel.warehouse.name
                    editCode = viewModel.warehouse.code
                    editAddress = viewModel.warehouse.address
                    editCapacity = "\(viewModel.warehouse.capacity)"
                    showEditSheet = true
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            if await viewModel.toggleActive() {
                                onChanged()
                            }
                        }
                    } label: {
                        Label(
                            viewModel.warehouse.isActive ? "Deactivate" : "Activate",
                            systemImage: viewModel.warehouse.isActive ? "pause.circle" : "checkmark.circle"
                        )
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Warehouse", systemImage: "trash")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
                .help("Warehouse actions")
            }
        }
        .sheet(isPresented: $showEditSheet) {
            WarehouseFormView(
                title: "Edit Warehouse",
                name: $editName,
                code: $editCode,
                address: $editAddress,
                capacity: $editCapacity,
                onSave: {
                    var updated = viewModel.warehouse
                    updated.name = editName
                    updated.code = editCode
                    updated.address = editAddress
                    updated.capacity = Int(editCapacity) ?? 0
                    updated.updatedAt = Date()
                    viewModel.applyUpdate(updated)
                    onSave(updated)
                    showEditSheet = false
                    Task { await viewModel.loadStats() }
                },
                onCancel: { showEditSheet = false }
            )
        }
        .alert("Delete Warehouse?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if await viewModel.deleteWarehouse() {
                        onChanged()
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete \(viewModel.warehouse.name) and all its data.")
        }
        .onChange(of: viewModel.successMessage) {
            if let message = viewModel.successMessage, !message.isEmpty {
                toastMessage = message
                showSuccessToast = true
                viewModel.successMessage = nil
            }
        }
        .overlay(alignment: .top) {
            if let error = viewModel.errorMessage {
                WMSErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
                .padding()
            }
        }
        .wmsToast(isPresented: $showSuccessToast, message: toastMessage)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.warehouse.name)
                    .font(.wmsLargeTitle)
                Text(viewModel.warehouse.code)
                    .font(.wmsMonospace)
                    .foregroundColor(.wmsTextSecondary)
            }
            Spacer()
            WMSBadge(
                text: viewModel.warehouse.isActive ? "Active" : "Inactive",
                color: viewModel.warehouse.isActive ? .wmsSuccess : .wmsTextSecondary
            )
            .padding(.top, 8)
        }
    }

    private func statsStrip(_ stats: WarehouseStats) -> some View {
        HStack(spacing: 12) {
            WMSStatCard(
                title: "SKUs",
                value: "\(stats.skuCount)",
                icon: "square.grid.2x2",
                color: .wmsInfo,
                subtitle: "Distinct items"
            )
            WMSStatCard(
                title: "Units in Stock",
                value: stats.unitCount.formatted(),
                icon: "shippingbox",
                color: .wmsSuccess,
                subtitle: "On hand"
            )
            WMSStatCard(
                title: "Inventory Value",
                value: stats.totalValue.formatted(
                    .wmsCurrency.precision(.fractionLength(0))
                ),
                icon: "indianrupeesign",
                color: .wmsAccent,
                subtitle: "At unit cost"
            )
            WMSStatCard(
                title: "Utilisation",
                value: "\(Int(stats.utilisation))%",
                icon: "gauge",
                color: utilisationColor(stats.utilisation),
                subtitle: "\(stats.unitCount.formatted()) of \(viewModel.warehouse.capacity.formatted()) units"
            )
        }
    }

    private func capacityCard(_ stats: WarehouseStats) -> some View {
        WMSCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Capacity Utilisation")
                        .font(.wmsCaption)
                        .textCase(.uppercase)
                        .tracking(0.8)
                        .foregroundColor(.wmsTextSecondary)
                    Spacer()
                    Text("\(Int(stats.utilisation))% used")
                        .font(.wmsMonospaceCaption)
                        .foregroundColor(utilisationColor(stats.utilisation))
                }
                ProgressView(value: min(stats.utilisation, 100), total: 100)
                    .progressViewStyle(.linear)
                    .tint(utilisationColor(stats.utilisation))
                HStack {
                    Text("\(stats.unitCount.formatted()) units in stock")
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextTertiary)
                    Spacer()
                    Text("Capacity \(viewModel.warehouse.capacity.formatted()) units")
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextTertiary)
                }
            }
        }
    }

    private func chartsRow(_ stats: WarehouseStats) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ChartCard(title: "Stock Movement Trend", icon: "chart.xyaxis.line") {
                MovementTrendChart(trend: stats.movementTrend)
            }
            if !stats.categorySummaries.isEmpty {
                ChartCard(title: "Item Categories", icon: "chart.pie") {
                    ValuePieChart(
                        points: stats.categorySummaries.map {
                            (label: $0.category, value: $0.totalValue)
                        },
                        innerRatio: 0.6,
                        centerTitle: "Value",
                        centerValue: stats.totalValue.formatted(
                            .wmsCurrency.precision(.fractionLength(0))
                        )
                    )
                }
            }
        }
    }

    private func lowStockCard(_ stats: WarehouseStats) -> some View {
        ChartCard(title: "Low Stock Items", icon: "exclamationmark.triangle") {
            VStack(spacing: 10) {
                ForEach(stats.lowStockItems) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.wmsWarning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.wmsBody)
                                .foregroundColor(.wmsTextPrimary)
                            Text("\(item.sku) · \(item.currentQuantity) left (min \(item.minimumThreshold))")
                                .font(.wmsMonospaceCaption)
                                .foregroundColor(.wmsTextSecondary)
                        }
                        Spacer()
                        Button("View in Inventory") {
                            onSelectItem(item.id)
                        }
                        .controlSize(.small)
                    }
                    if item.id != stats.lowStockItems.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func recentActivityCard(_ stats: WarehouseStats) -> some View {
        ChartCard(title: "Recent Activity", icon: "clock.arrow.circlepath") {
            VStack(spacing: 10) {
                ForEach(stats.recentMovements) { movement in
                    HStack(spacing: 12) {
                        Image(systemName: movementIcon(movement.movementType))
                            .foregroundColor(movementColor(movement.movementType))
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stats.itemNames[movement.itemID] ?? "Unknown item")
                                .font(.wmsBody)
                                .foregroundColor(.wmsTextPrimary)
                                .lineLimit(1)
                            Text(movementLabel(movement.movementType))
                                .font(.wmsMonospaceCaption)
                                .foregroundColor(.wmsTextSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(movement.quantity)")
                                .font(.wmsMonospace)
                                .foregroundColor(.wmsTextPrimary)
                            Text(movement.recordedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.wmsMonospaceCaption)
                                .foregroundColor(.wmsTextTertiary)
                        }
                    }
                    if movement.id != stats.recentMovements.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var detailsBox: some View {
        GroupBox("Details") {
            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                GridRow {
                    Text("Address")
                        .foregroundColor(.wmsTextSecondary)
                    Text(viewModel.warehouse.address)
                }
                GridRow {
                    Text("Capacity")
                        .foregroundColor(.wmsTextSecondary)
                    Text("\(viewModel.warehouse.capacity) units")
                }
                GridRow {
                    Text("Status")
                        .foregroundColor(.wmsTextSecondary)
                    WMSBadge(
                        text: viewModel.warehouse.isActive ? "Active" : "Inactive",
                        color: viewModel.warehouse.isActive ? .wmsSuccess : .wmsTextSecondary
                    )
                }
                GridRow {
                    Text("Created")
                        .foregroundColor(.wmsTextSecondary)
                    Text(viewModel.warehouse.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                GridRow {
                    Text("Updated")
                        .foregroundColor(.wmsTextSecondary)
                    Text(viewModel.warehouse.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func utilisationColor(_ value: Double) -> Color {
        if value > 90 { return .wmsDestructive }
        if value > 75 { return .wmsWarning }
        return .wmsSuccess
    }

    private func movementIcon(_ type: MovementType) -> String {
        switch type {
        case .stockIn: return "arrow.down.circle.fill"
        case .stockOut: return "arrow.up.circle.fill"
        case .adjustment: return "arrow.left.arrow.right.circle.fill"
        }
    }

    private func movementColor(_ type: MovementType) -> Color {
        switch type {
        case .stockIn: return .wmsSuccess
        case .stockOut: return .wmsWarning
        case .adjustment: return .wmsInfo
        }
    }

    private func movementLabel(_ type: MovementType) -> String {
        switch type {
        case .stockIn: return "Stock In"
        case .stockOut: return "Stock Out"
        case .adjustment: return "Adjustment"
        }
    }
}
