import SwiftUI
import WMSCore
import WMSDesignSystem
import WMSServices

public enum SearchNavigationTarget: String, CaseIterable {
    case warehouses
    case inventory
    case employees
}

public struct GlobalSearchView: View {
    @State var viewModel: GlobalSearchViewModel
    @Environment(\.dismiss) private var dismiss
    let onNavigate: (SearchNavigationTarget) -> Void

    public init(viewModel: GlobalSearchViewModel, onNavigate: @escaping (SearchNavigationTarget) -> Void) {
        self.viewModel = viewModel
        self.onNavigate = onNavigate
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.wmsTextSecondary)
                TextField("Search warehouses, SKUs, employees...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .accessibilityLabel("Global search")
                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.query = ""
                        viewModel.clearResults()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.wmsTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear search")
                }
            }
            .padding()
            .background(Color.wmsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if viewModel.isSearching {
                Spacer()
                WMSLoadingView(message: "Searching...")
                Spacer()
            } else if viewModel.hasResults {
                List {
                    if !viewModel.warehouseResults.isEmpty {
                        Section("Warehouses (\(viewModel.warehouseResults.count))") {
                            ForEach(viewModel.warehouseResults) { warehouse in
                                SearchRow(
                                    icon: "building.2",
                                    title: warehouse.name,
                                    subtitle: warehouse.code,
                                    detail: warehouse.address
                                )
                                .onTapGesture {
                                    onNavigate(.warehouses)
                                    dismiss()
                                }
                            }
                        }
                    }
                    if !viewModel.inventoryResults.isEmpty {
                        Section("Inventory (\(viewModel.inventoryResults.count))") {
                            ForEach(viewModel.inventoryResults) { item in
                                SearchRow(
                                    icon: "shippingbox",
                                    title: item.name,
                                    subtitle: item.sku,
                                    detail: "\(item.currentQuantity) \(item.unitOfMeasure)"
                                )
                                .onTapGesture {
                                    onNavigate(.inventory)
                                    dismiss()
                                }
                            }
                        }
                    }
                    if !viewModel.employeeResults.isEmpty {
                        Section("Employees (\(viewModel.employeeResults.count))") {
                            ForEach(viewModel.employeeResults) { employee in
                                SearchRow(
                                    icon: "person",
                                    title: employee.fullName,
                                    subtitle: employee.employeeCode,
                                    detail: employee.jobTitle
                                )
                                .onTapGesture {
                                    onNavigate(.employees)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            } else if !viewModel.query.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No matches found for \"\(viewModel.query)\".")
                )
            } else {
                ContentUnavailableView(
                    "Search",
                    systemImage: "magnifyingglass",
                    description: Text("Type to search across all entities.")
                )
            }
        }
        .frame(width: 500, height: 400)
        .navigationTitle("Search")
    }
}

private struct SearchRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.wmsAccent)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.wmsBody)
                Text(subtitle)
                    .font(.wmsMonospaceCaption)
                    .foregroundColor(.wmsTextSecondary)
            }
            Spacer()
            Text(detail)
                .font(.wmsCaption)
                .foregroundColor(.wmsTextTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle), \(detail)")
    }
}
