import SwiftUI
import WMSCore
import WMSServices
import WMSDesignSystem

public struct DashboardView: View {
    let viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.data == nil {
                WMSLoadingView(message: "Loading dashboard...")
            } else if let data = viewModel.data {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerBar

                        LazyVGrid(columns: gridColumns, spacing: 14) {
                            WMSStatCard(
                                title: "Active Warehouses",
                                value: "\(data.activeWarehouseCount)",
                                icon: "building.2",
                                color: .wmsAccent,
                                subtitle: "\(data.warehouseSummaries.count) registered"
                            )
                            WMSStatCard(
                                title: "Total SKUs",
                                value: "\(data.totalSKUCount)",
                                icon: "shippingbox",
                                color: .wmsInfo,
                                subtitle: "Across all warehouses"
                            )
                            WMSStatCard(
                                title: "Inventory Value",
                                value: data.totalInventoryValue.formatted(.currency(code: "USD")),
                                icon: "dollarsign.circle",
                                color: .wmsSuccess,
                                subtitle: "Total stock value"
                            )
                            WMSStatCard(
                                title: "Active Employees",
                                value: "\(data.employeeCount)",
                                icon: "person.2",
                                color: .cyan,
                                subtitle: "Warehouse staff"
                            )
                            WMSStatCard(
                                title: "Active Transfers",
                                value: "\(data.activeTransferCount)",
                                icon: "arrow.triangle.2.circlepath",
                                color: .orange,
                                subtitle: "In progress"
                            )
                            WMSStatCard(
                                title: "Low Stock Alerts",
                                value: "\(data.lowStockAlerts.count)",
                                icon: "exclamationmark.triangle",
                                color: data.lowStockAlerts.isEmpty ? .wmsTextSecondary : .wmsDestructive,
                                subtitle: data.lowStockAlerts.isEmpty ? "All items healthy" : "Requires attention"
                            )
                        }

                        if !data.warehouseSummaries.isEmpty {
                            sectionHeader(icon: "building.2", title: "Warehouse Utilisation", count: data.warehouseSummaries.count)
                            VStack(spacing: 0) {
                                ForEach(Array(data.warehouseSummaries.enumerated()), id: \.element.warehouse.id) { index, summary in
                                    warehouseUtilRow(summary)
                                    if index < data.warehouseSummaries.count - 1 {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color.wmsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
                            )
                        }

                        if !data.lowStockAlerts.isEmpty {
                            sectionHeader(icon: "exclamationmark.triangle", title: "Low Stock Alerts", count: data.lowStockAlerts.count)
                            VStack(spacing: 0) {
                                ForEach(Array(data.lowStockAlerts.prefix(5).enumerated()), id: \.element.id) { index, alert in
                                    alertRow(alert)
                                    if index < min(data.lowStockAlerts.count, 5) - 1 {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color.wmsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
                            )
                        }

                        if !data.inProgressTransfers.isEmpty {
                            sectionHeader(icon: "arrow.triangle.2.circlepath", title: "Active Transfers", count: data.inProgressTransfers.count)
                            VStack(spacing: 0) {
                                ForEach(Array(data.inProgressTransfers.prefix(5).enumerated()), id: \.element.id) { index, transfer in
                                    transferRow(transfer, data: data)
                                    if index < min(data.inProgressTransfers.count, 5) - 1 {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color.wmsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
                            )
                        }

                        if !data.recentMovements.isEmpty {
                            sectionHeader(icon: "clock.arrow.circlepath", title: "Recent Stock Movements", count: data.recentMovements.count)
                            VStack(spacing: 0) {
                                ForEach(Array(data.recentMovements.prefix(8).enumerated()), id: \.element.id) { index, movement in
                                    movementRow(movement, data: data)
                                    if index < min(data.recentMovements.count, 8) - 1 {
                                        Divider()
                                            .padding(.leading, 44)
                                    }
                                }
                            }
                            .background(Color.wmsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.wmsSeparator.opacity(0.5), lineWidth: 1)
                            )
                        }

                        if let date = viewModel.lastRefreshDate {
                            HStack {
                                Spacer()
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                        .foregroundColor(.wmsTextTertiary)
                                    Text("Last updated \(date.formatted(date: .abbreviated, time: .standard))")
                                        .font(.wmsCaption)
                                        .foregroundColor(.wmsTextTertiary)
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                            .frame(width: 12, height: 12)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.wmsSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
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
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible(minimum: 200), spacing: 14),
            GridItem(.flexible(minimum: 200), spacing: 14),
            GridItem(.flexible(minimum: 200), spacing: 14)
        ]
    }

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(size: 28, weight: .bold))
                Text("Warehouse performance overview")
                    .font(.wmsBody)
                    .foregroundColor(.wmsTextSecondary)
            }
            Spacer()
            if viewModel.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Refreshing...")
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.wmsSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.wmsSeparator, lineWidth: 1)
                )
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            label: {
                Label("No Data", systemImage: "chart.bar")
            },
            description: {
                Text("Add warehouses and inventory items to see your dashboard.")
            },
            actions: {
                Text("Dashboard will populate automatically once you have data.")
                    .font(.wmsCaption)
                    .foregroundColor(.wmsTextTertiary)
            }
        )
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

    private func warehouseUtilRow(_ summary: WarehouseSummary) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 14))
                .foregroundColor(.wmsTextTertiary)
                .frame(width: 20)

            Text(summary.warehouse.name)
                .font(.wmsBody)
                .frame(width: 130, alignment: .leading)
                .lineLimit(1)

            ProgressView(value: min(summary.utilisation, 100), total: 100)
                .tint(utilisationColor(summary.utilisation))
                .frame(maxWidth: .infinity)

            Text("\(Int(summary.utilisation))%")
                .font(.wmsMonospaceCaption)
                .foregroundColor(utilisationColor(summary.utilisation))
                .frame(width: 36, alignment: .trailing)

            Text("\(summary.totalItems) items")
                .font(.wmsCaption)
                .foregroundColor(.wmsTextTertiary)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func alertRow(_ alert: AlertRecord) -> some View {
        HStack(spacing: 12) {
            Image(systemName: alert.severity == .critical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(alert.severity == .critical ? .wmsDestructive : .wmsWarning)
                .frame(width: 20)

            Text(alert.message)
                .font(.wmsBody)
                .lineLimit(1)

            Spacer()

            Text(alert.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.wmsCaption)
                .foregroundColor(.wmsTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func transferRow(_ transfer: TransferOrder, data: DashboardData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14))
                .foregroundColor(.wmsTextTertiary)
                .frame(width: 20)

            WMSBadge(text: transfer.status.rawValue.capitalized, color: statusColor(transfer.status))

            Text(transfer.transferCode)
                .font(.wmsMonospace)

            Text("\(warehouseName(data, transfer.sourceWarehouseID)) → \(warehouseName(data, transfer.destinationWarehouseID))")
                .font(.wmsCaption)
                .foregroundColor(.wmsTextSecondary)
                .lineLimit(1)

            Spacer()

            Text(transfer.requestedDate.formatted(date: .abbreviated, time: .omitted))
                .font(.wmsCaption)
                .foregroundColor(.wmsTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func movementRow(_ movement: StockMovement, data: DashboardData) -> some View {
        HStack(spacing: 12) {
            Image(systemName: movement.movementType == .stockIn ? "arrow.down.to.line" : movement.movementType == .stockOut ? "arrow.up.from.line" : "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(movementColor(movement.movementType))
                .frame(width: 20)

            WMSBadge(
                text: movement.movementType.rawValue.capitalized,
                color: movementColor(movement.movementType)
            )

            if let itemName = data.itemNames[movement.itemID] {
                Text(itemName)
                    .font(.wmsBody)
                    .lineLimit(1)
                    .frame(width: 150, alignment: .leading)
            }

            Text("\(movement.quantity)")
                .font(.wmsMonospace)
                .foregroundColor(.wmsTextPrimary)
                .frame(width: 50, alignment: .trailing)

            Spacer()

            Text(movement.recordedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.wmsCaption)
                .foregroundColor(.wmsTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func warehouseName(_ data: DashboardData, _ id: UUID) -> String {
        data.warehouseSummaries.first(where: { $0.warehouse.id == id })?.warehouse.name ?? "Unknown"
    }

    private func utilisationColor(_ value: Double) -> Color {
        if value > 90 { return .wmsDestructive }
        if value > 75 { return .wmsWarning }
        return .wmsSuccess
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
