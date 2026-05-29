import SwiftUI
import WMSCore
import WMSDesignSystem

public struct WarehouseDetailView: View {
    let warehouse: Warehouse
    let onSave: (Warehouse) -> Void

    @State private var showEditSheet = false
    @State private var editName = ""
    @State private var editCode = ""
    @State private var editAddress = ""
    @State private var editCapacity = ""

    public init(warehouse: Warehouse, onSave: @escaping (Warehouse) -> Void) {
        self.warehouse = warehouse
        self.onSave = onSave
    }

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
                        editName = warehouse.name
                        editCode = warehouse.code
                        editAddress = warehouse.address
                        editCapacity = "\(warehouse.capacity)"
                        showEditSheet = true
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
                        GridRow {
                            Text("Updated")
                                .foregroundColor(.wmsTextSecondary)
                            Text(warehouse.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle(warehouse.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    editName = warehouse.name
                    editCode = warehouse.code
                    editAddress = warehouse.address
                    editCapacity = "\(warehouse.capacity)"
                    showEditSheet = true
                }
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
                    var updated = warehouse
                    updated.name = editName
                    updated.code = editCode
                    updated.address = editAddress
                    updated.capacity = Int(editCapacity) ?? 0
                    updated.updatedAt = Date()
                    onSave(updated)
                    showEditSheet = false
                },
                onCancel: { showEditSheet = false }
            )
        }
    }
}
