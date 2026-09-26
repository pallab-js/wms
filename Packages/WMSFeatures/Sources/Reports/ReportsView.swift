import SwiftUI
import WMSCore
import WMSServices
import WMSDesignSystem

public struct ReportsView: View {
    let viewModel: ReportsViewModel

    @State private var exportDocument: CSVDocument?
    @State private var showExporter = false

    public init(viewModel: ReportsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.data == nil {
                WMSLoadingView(message: "Loading reports...")
            } else if let data = viewModel.data {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerBar

                        if !data.valuationByWarehouse.isEmpty {
                            HStack(alignment: .top, spacing: 14) {
                                ChartCard(title: "Inventory Value by Warehouse", icon: "chart.donut") {
                                    ValuePieChart(
                                        points: data.valuationByWarehouse.map { (label: $0.warehouseName, value: $0.totalValue) },
                                        innerRatio: 0.58,
                                        centerTitle: "Total Value",
                                        centerValue: data.valuationByWarehouse
                                            .reduce(0.0) { $0 + $1.totalValue }
                                            .formatted(.wmsCurrency)
                                    )
                                }
                                ChartCard(title: "Valuation by Category", icon: "chart.pie") {
                                    ValuePieChart(
                                        points: data.valuationByCategory.map { (label: $0.category, value: $0.totalValue) }
                                    )
                                }
                            }
                        }

                        sectionHeader(icon: "building.2", title: "Inventory Valuation by Warehouse", count: data.valuationByWarehouse.count)
                        card {
                            if data.valuationByWarehouse.isEmpty {
                                emptySection("No warehouse valuation data.")
                            } else {
                                valuationHeader("Warehouse")
                                ForEach(Array(data.valuationByWarehouse.enumerated()), id: \.element.warehouseID) { index, row in
                                    warehouseRow(row, maxValue: data.valuationByWarehouse.first?.totalValue ?? 0)
                                    if index < data.valuationByWarehouse.count - 1 {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                        }

                        sectionHeader(icon: "tag", title: "Valuation by Category", count: data.valuationByCategory.count)
                        card {
                            if data.valuationByCategory.isEmpty {
                                emptySection("No category valuation data.")
                            } else {
                                valuationHeader("Category")
                                ForEach(Array(data.valuationByCategory.enumerated()), id: \.element.category) { index, row in
                                    categoryRow(row, maxValue: data.valuationByCategory.first?.totalValue ?? 0)
                                    if index < data.valuationByCategory.count - 1 {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                        }

                        sectionHeader(icon: "arrow.left.arrow.right", title: "Stock Movement Activity", count: data.movementSummary.count)
                        card {
                            movementHeader()
                            ForEach(Array(data.movementSummary.enumerated()), id: \.element.type) { index, row in
                                movementRow(row)
                                if index < data.movementSummary.count - 1 {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }

                        sectionHeader(icon: "arrow.triangle.2.circlepath", title: "Transfer Orders", count: data.transferSummary.reduce(0) { $0 + $1.count })
                        card {
                            transferHeader()
                            ForEach(Array(data.transferSummary.enumerated()), id: \.element.status) { index, row in
                                transferRow(row)
                                if index < data.transferSummary.count - 1 {
                                    Divider().padding(.leading, 44)
                                }
                            }
                        }

                        sectionHeader(icon: "exclamationmark.triangle", title: "Low Stock Report", count: data.lowStockItems.count)
                        card {
                            if data.lowStockItems.isEmpty {
                                emptySection("All items are above their minimum thresholds.")
                            } else {
                                lowStockHeader()
                                ForEach(Array(data.lowStockItems.enumerated()), id: \.element.id) { index, item in
                                    lowStockRow(item, warehouseNames: data.warehouseNames)
                                    if index < data.lowStockItems.count - 1 {
                                        Divider().padding(.leading, 44)
                                    }
                                }
                            }
                        }

                        footer(data)
                    }
                    .padding(24)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            } else {
                emptyState
            }
        }
        .overlay(alignment: .top) {
            if let error = viewModel.errorMessage {
                WMSErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .commaSeparatedText,
            defaultFilename: "warehouseos-reports"
        ) { result in
            if case .failure = result {
                viewModel.errorMessage = "CSV export failed."
            }
        }
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reports")
                    .font(.system(size: 28, weight: .bold))
                Text("Valuation, activity and inventory analytics")
                    .font(.wmsBody)
                    .foregroundColor(.wmsTextSecondary)
            }
            Spacer()
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .accessibilityLabel("Refresh reports")
            .disabled(viewModel.isLoading)
            Button {
                export()
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Export reports as CSV")
            .disabled(viewModel.data == nil)
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }

    private func export() {
        guard let csv = viewModel.exportCSV() else { return }
        exportDocument = CSVDocument(text: csv)
        showExporter = true
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.wmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
        )
    }

    private func tableHeaderStyle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12, content: content)
            .font(.wmsMonospaceCaption)
            .foregroundColor(.wmsTextTertiary)
            .textCase(.uppercase)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.wmsSeparator.opacity(0.15))
    }

    private func valuationHeader(_ firstColumn: String) -> some View {
        tableHeaderStyle {
            Color.clear.frame(width: 20, height: 1)
            Text(firstColumn)
                .frame(width: 140, alignment: .leading)
            Text("Share")
                .frame(maxWidth: .infinity)
            Text("SKUs")
                .frame(width: 48, alignment: .trailing)
            Text("Units")
                .frame(width: 64, alignment: .trailing)
            Text("Value")
                .frame(width: 100, alignment: .trailing)
        }
    }

    private func movementHeader() -> some View {
        tableHeaderStyle {
            Color.clear.frame(width: 20, height: 1)
            Text("Type")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Movements")
                .frame(width: 100, alignment: .trailing)
            Text("Total Quantity")
                .frame(width: 100, alignment: .trailing)
        }
    }

    private func transferHeader() -> some View {
        tableHeaderStyle {
            Color.clear.frame(width: 20, height: 1)
            Text("Status")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Count")
                .frame(width: 100, alignment: .trailing)
        }
    }

    private func lowStockHeader() -> some View {
        tableHeaderStyle {
            Color.clear.frame(width: 20, height: 1)
            Text("SKU")
                .frame(width: 80, alignment: .leading)
            Text("Item")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Warehouse")
                .frame(width: 140, alignment: .leading)
            Text("Stock")
                .frame(width: 72, alignment: .trailing)
            Text("Value at Risk")
                .frame(width: 100, alignment: .trailing)
        }
    }

    private func warehouseRow(_ row: WarehouseValuation, maxValue: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 14))
                .foregroundColor(.wmsTextTertiary)
                .frame(width: 20)
            Text(row.warehouseName)
                .font(.wmsBody)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
            shareBar(value: row.totalValue, maxValue: maxValue)
            Text("\(row.skuCount)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextSecondary)
                .frame(width: 48, alignment: .trailing)
            Text("\(row.unitCount)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextSecondary)
                .frame(width: 64, alignment: .trailing)
            Text(row.totalValue.formatted(.wmsCurrency))
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextPrimary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.warehouseName): \(row.skuCount) SKUs, \(row.unitCount) units, \(row.totalValue.formatted(.wmsCurrency))")
    }

    private func categoryRow(_ row: CategoryValuation, maxValue: Double) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "tag")
                .font(.system(size: 14))
                .foregroundColor(.wmsTextTertiary)
                .frame(width: 20)
            Text(row.category)
                .font(.wmsBody)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
            shareBar(value: row.totalValue, maxValue: maxValue)
            Text("\(row.skuCount)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextSecondary)
                .frame(width: 48, alignment: .trailing)
            Text("\(row.unitCount)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextSecondary)
                .frame(width: 64, alignment: .trailing)
            Text(row.totalValue.formatted(.wmsCurrency))
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextPrimary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.category): \(row.skuCount) SKUs, \(row.unitCount) units, \(row.totalValue.formatted(.wmsCurrency))")
    }

    private func movementRow(_ row: MovementSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: movementIcon(row.type))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(movementColor(row.type))
                .frame(width: 20)
            WMSBadge(text: row.label, color: movementColor(row.type))
            Spacer()
            Text("\(row.count)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextPrimary)
                .frame(width: 100, alignment: .trailing)
            Text("\(row.totalQuantity)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextSecondary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label): \(row.count) movements, total quantity \(row.totalQuantity)")
    }

    private func transferRow(_ row: TransferSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14))
                .foregroundColor(.wmsTextTertiary)
                .frame(width: 20)
            WMSBadge(text: row.label, color: statusColor(row.status))
            Spacer()
            Text("\(row.count)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(row.count > 0 ? .wmsTextPrimary : .wmsTextTertiary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.label): \(row.count) transfer orders")
    }

    private func lowStockRow(_ item: InventoryItem, warehouseNames: [UUID: String]) -> some View {
        let atRisk = Double(item.currentQuantity) * item.unitCost
        return HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(item.currentQuantity == 0 ? .wmsDestructive : .wmsWarning)
                .frame(width: 20)
            Text(item.sku)
                .font(.wmsMonospace)
                .frame(width: 80, alignment: .leading)
            Text(item.name)
                .font(.wmsBody)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(warehouseNames[item.warehouseID] ?? "Unknown")
                .font(.wmsCaption)
                .foregroundColor(.wmsTextSecondary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)
            Text("\(item.currentQuantity) / \(item.minimumThreshold)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(item.currentQuantity == 0 ? .wmsDestructive : .wmsWarning)
                .frame(width: 72, alignment: .trailing)
            Text(atRisk.formatted(.wmsCurrency))
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextPrimary)
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), SKU \(item.sku): \(item.currentQuantity) of minimum \(item.minimumThreshold)")
    }

    private func shareBar(value: Double, maxValue: Double) -> some View {
        let share = maxValue > 0 ? min(value / maxValue, 1) : 0
        return ProgressView(value: share)
            .tint(.wmsInfo)
            .frame(maxWidth: .infinity)
    }

    private func sectionHeader(icon: String, title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.wmsTextSecondary)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.wmsTextPrimary)
            Spacer()
            Text("\(count)")
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.wmsSeparator.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding(.top, 4)
    }

    private func emptySection(_ message: String) -> some View {
        Text(message)
            .font(.wmsCaption)
            .foregroundColor(.wmsTextTertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func footer(_ data: ReportsData) -> some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.wmsTextTertiary)
                Text("Generated \(data.generatedAt.formatted(date: .abbreviated, time: .standard))")
                    .font(.wmsCaption)
                    .foregroundColor(.wmsTextTertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.wmsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            label: {
                Label("No Reports Data", systemImage: "chart.bar.doc.horizontal")
            },
            description: {
                Text("Add warehouses and inventory items to generate reports.")
            },
            actions: {
                Text("Reports will populate automatically once you have data.")
                    .font(.wmsCaption)
                    .foregroundColor(.wmsTextTertiary)
            }
        )
    }

    private func movementIcon(_ type: MovementType) -> String {
        switch type {
        case .stockIn: return "arrow.down.to.line"
        case .stockOut: return "arrow.up.from.line"
        case .adjustment: return "arrow.left.arrow.right"
        }
    }

    private func movementColor(_ type: MovementType) -> Color {
        switch type {
        case .stockIn: return .wmsSuccess
        case .stockOut: return .wmsWarning
        case .adjustment: return .wmsInfo
        }
    }

    private func statusColor(_ status: TransferStatus) -> Color {
        switch status {
        case .draft: return .wmsTextSecondary
        case .submitted: return .wmsInfo
        case .approved: return .wmsSuccess
        case .inTransit: return .orange
        case .completed: return .green
        case .cancelled: return .wmsDestructive
        }
    }
}
