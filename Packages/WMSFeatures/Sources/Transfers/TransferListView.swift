import SwiftUI
import WMSCore
import WMSDesignSystem

public struct TransferListView: View {
    @Bindable var viewModel: TransferListViewModel
    @Binding var warehouses: [Warehouse]

    @State private var showCreateSheet = false

    public init(viewModel: TransferListViewModel, warehouses: Binding<[Warehouse]>) {
        self.viewModel = viewModel
        self._warehouses = warehouses
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                WMSLoadingView(message: "Loading transfers...")
            } else if viewModel.transfers.isEmpty {
                ContentUnavailableView(
                    "No Transfers",
                    systemImage: "arrow.triangle.2.circlepath",
                    description: Text("Create a transfer order to move stock between warehouses.")
                )
            } else {
                Table(viewModel.transfers) {
                    TableColumn("Code") { order in
                        Text(order.transferCode)
                            .font(.wmsMonospace)
                    }
                    .width(min: 100, max: 140)

                    TableColumn("From") { order in
                        Text(warehouseName(for: order.sourceWarehouseID))
                            .font(.wmsBody)
                    }

                    TableColumn("To") { order in
                        Text(warehouseName(for: order.destinationWarehouseID))
                            .font(.wmsBody)
                    }

                    TableColumn("Status") { order in
                        WMSBadge(text: order.status.rawValue.replacingOccurrences(of: "(?=[A-Z])", with: " ", options: .regularExpression).capitalized, color: statusColor(order.status))
                    }
                    .width(120)

                    TableColumn("Date") { order in
                        Text(order.requestedDate, format: .dateTime.month().day())
                            .font(.wmsCaption)
                            .foregroundColor(.wmsTextSecondary)
                    }
                    .width(80)

                    TableColumn("Actions") { order in
                        TransferActionButtons(order: order, viewModel: viewModel)
                    }
                    .width(120)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("New Transfer", systemImage: "plus")
                }
                .keyboardShortcut("n")
                .disabled(warehouses.count < 2)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            TransferFormView(
                viewModel: viewModel,
                warehouses: warehouses,
                inventoryItems: viewModel.inventoryItems
            )
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

    private func warehouseName(for id: UUID) -> String {
        warehouses.first { $0.id == id }?.name ?? "Unknown"
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

struct TransferActionButtons: View {
    let order: TransferOrder
    let viewModel: TransferListViewModel

    var body: some View {
        HStack(spacing: 4) {
            switch order.status {
            case .draft:
                Button("Submit") { Task { await viewModel.submitTransfer(id: order.id) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            case .submitted:
                Button("Approve") { Task { await viewModel.approveTransfer(id: order.id) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Cancel") { Task { await viewModel.cancelTransfer(id: order.id) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.wmsDestructive)
            case .approved:
                Button("Execute") { Task { await viewModel.executeTransfer(id: order.id) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Cancel") { Task { await viewModel.cancelTransfer(id: order.id) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.wmsDestructive)
            case .inTransit:
                Button("Complete") { Task { await viewModel.completeTransfer(id: order.id) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            default:
                EmptyView()
            }
        }
    }
}
