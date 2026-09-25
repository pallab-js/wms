import SwiftUI
import WMSCore
import WMSDesignSystem

public struct WarehouseDetailView: View {
    let warehouse: Warehouse
    let onSave: (Warehouse) -> Void

    @State private var current: Warehouse
    @State private var showEditSheet = false
    @State private var editName = ""
    @State private var editCode = ""
    @State private var editAddress = ""
    @State private var editCapacity = ""

    public init(warehouse: Warehouse, onSave: @escaping (Warehouse) -> Void) {
        self.warehouse = warehouse
        self.onSave = onSave
        self._current = State(initialValue: warehouse)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(current.name)
                            .font(.wmsLargeTitle)
                        Text(current.code)
                            .font(.wmsMonospace)
                            .foregroundColor(.wmsTextSecondary)
                    }
                    Spacer()
                }

                Divider()

                GroupBox("Details") {
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                        GridRow {
                            Text("Address")
                                .foregroundColor(.wmsTextSecondary)
                            Text(current.address)
                        }
                        GridRow {
                            Text("Capacity")
                                .foregroundColor(.wmsTextSecondary)
                            Text("\(current.capacity) units")
                        }
                        GridRow {
                            Text("Status")
                                .foregroundColor(.wmsTextSecondary)
                            WMSBadge(
                                text: current.isActive ? "Active" : "Inactive",
                                color: current.isActive ? .wmsSuccess : .wmsTextSecondary
                            )
                        }
                        GridRow {
                            Text("Created")
                                .foregroundColor(.wmsTextSecondary)
                            Text(current.createdAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        GridRow {
                            Text("Updated")
                                .foregroundColor(.wmsTextSecondary)
                            Text(current.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .navigationTitle(current.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    editName = current.name
                    editCode = current.code
                    editAddress = current.address
                    editCapacity = "\(current.capacity)"
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
                    var updated = current
                    updated.name = editName
                    updated.code = editCode
                    updated.address = editAddress
                    updated.capacity = Int(editCapacity) ?? 0
                    updated.updatedAt = Date()
                    current = updated
                    onSave(updated)
                    showEditSheet = false
                },
                onCancel: { showEditSheet = false }
            )
        }
    }
}
