import SwiftUI
import WMSCore
import WMSDesignSystem

public struct DashboardView: View {
    let viewModel: DashboardViewModel

    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                WMSLoadingView(message: "Loading dashboard...")
            } else if let data = viewModel.data {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Dashboard")
                            .font(.wmsLargeTitle)

                        // KPI Cards
                        HStack(spacing: 16) {
                            WMSStatCard(
                                title: "Warehouses",
                                value: "\(data.activeWarehouseCount)",
                                icon: "building.2",
                                color: .wmsAccent
                            )
                            WMSStatCard(
                                title: "Total SKUs",
                                value: "\(data.totalSKUCount)",
                                icon: "shippingbox",
                                color: .wmsInfo
                            )
                            WMSStatCard(
                                title: "Inventory Value",
                                value: data.totalInventoryValue.formatted(.currency(code: "USD")),
                                icon: "dollarsign.circle",
                                color: .wmsSuccess
                            )
                        }

                        // Warehouse Utilisation
                        if !data.warehouseSummaries.isEmpty {
                            GroupBox("Warehouse Utilisation") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(data.warehouseSummaries, id: \.warehouse.id) { summary in
                                        HStack {
                                            Text(summary.warehouse.name)
                                                .font(.wmsBody)
                                                .frame(width: 120, alignment: .leading)
                                            ProgressView(value: summary.utilisation, total: 100)
                                                .frame(maxWidth: .infinity)
                                            Text("\(Int(summary.utilisation))%")
                                                .font(.wmsMonospaceCaption)
                                                .frame(width: 40, alignment: .trailing)
                                        }
                                    }
                                }
                            }
                        }

                        // Recent Movements
                        if !data.recentMovements.isEmpty {
                            GroupBox("Recent Stock Movements") {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(data.recentMovements) { movement in
                                        HStack {
                                            WMSBadge(
                                                text: movement.movementType.rawValue.capitalized,
                                                color: movement.movementType == .stockIn ? .wmsSuccess : .wmsWarning
                                            )
                                            Text("\(movement.quantity)")
                                                .font(.wmsMonospace)
                                            Text("on \(movement.recordedAt.formatted(date: .abbreviated, time: .shortened))")
                                                .font(.wmsCaption)
                                                .foregroundColor(.wmsTextSecondary)
                                            Spacer()
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.bar",
                    description: Text("Add warehouses and inventory to see dashboard data.")
                )
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
    }
}
