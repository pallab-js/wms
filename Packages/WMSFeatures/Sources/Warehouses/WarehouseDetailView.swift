import SwiftUI
import WMSCore
import WMSDesignSystem

public struct WarehouseDetailView: View {
    let warehouse: Warehouse
    let onEdit: () -> Void

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(warehouse.name)
                            .font(.wmsLargeTitle)
                        Text(warehouse.code)
                            .font(.wmsMonospace)
                            .foregroundColor(.wmsTextSecondary)
                    }
                    Spacer()
                    Button("Edit") {
                        onEdit()
                    }
                }

                Divider()

                GroupBox("Details") {
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                        GridRow {
                            Text("Address")
                                .foregroundColor(.wmsTextSecondary)
                            Text(warehouse.address)
                        }
                        GridRow {
                            Text("Capacity")
                                .foregroundColor(.wmsTextSecondary)
                            Text("\(warehouse.capacity) units")
                        }
                        GridRow {
                            Text("Status")
                                .foregroundColor(.wmsTextSecondary)
                            WMSBadge(
                                text: warehouse.isActive ? "Active" : "Inactive",
                                color: warehouse.isActive ? .wmsSuccess : .wmsTextSecondary
                            )
                        }
                        GridRow {
                            Text("Created")
                                .foregroundColor(.wmsTextSecondary)
                            Text(warehouse.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle(warehouse.name)
    }
}
