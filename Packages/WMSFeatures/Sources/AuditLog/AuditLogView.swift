import SwiftUI
import WMSCore
import WMSDesignSystem
import WMSServices

public struct AuditLogView: View {
    @State var viewModel: AuditLogViewModel

    public init(viewModel: AuditLogViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.isLoading {
                WMSLoadingView(message: "Loading audit log...")
            } else if viewModel.entries.isEmpty {
                ContentUnavailableView(
                    "No Audit Entries",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Audit entries will appear here as operations are performed.")
                )
            } else {
                List {
                    ForEach(viewModel.entries) { entry in
                        AuditLogRow(entry: entry)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Audit Log")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Picker("Entity Type", selection: $viewModel.entityTypeFilter) {
                        Text("All Types").tag(String?.none)
                        Text("Warehouse").tag(String?.some("Warehouse"))
                        Text("InventoryItem").tag(String?.some("InventoryItem"))
                        Text("Employee").tag(String?.some("Employee"))
                        Text("TransferOrder").tag(String?.some("TransferOrder"))
                        Text("StockMovement").tag(String?.some("StockMovement"))
                    }
                    Picker("Action", selection: $viewModel.actionFilter) {
                        Text("All Actions").tag(String?.none)
                        Text("Created").tag(String?.some("created"))
                        Text("Updated").tag(String?.some("updated"))
                        Text("Deleted").tag(String?.some("deleted"))
                        Text("Deactivated").tag(String?.some("deactivated"))
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter audit entries")

                Button {
                    Task { await viewModel.loadEntries() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh audit log")
            }
        }
        .task { await viewModel.loadEntries() }
    }
}

private struct AuditLogRow: View {
    let entry: AuditEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.action.capitalized)
                        .font(.wmsHeadline)
                    Text(entry.entityType)
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextSecondary)
                    WMSBadge(text: entry.userRole, color: .wmsInfo)
                }
                Text("Entity: \(entry.entityID.uuidString.prefix(8))")
                    .font(.wmsMonospaceCaption)
                    .foregroundColor(.wmsTextTertiary)
                if let note = entry.note {
                    Text(note)
                        .font(.wmsCaption)
                        .foregroundColor(.wmsTextSecondary)
                }
            }

            Spacer()

            Text(formattedTimestamp(entry.timestamp))
                .font(.wmsMonospaceCaption)
                .foregroundColor(.wmsTextTertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.action) \(entry.entityType) by \(entry.userRole) at \(entry.timestamp.formatted())")
    }

    private var iconName: String {
        switch entry.action {
        case "created": return "plus.circle.fill"
        case "updated": return "pencil.circle.fill"
        case "deleted", "deactivated": return "minus.circle.fill"
        default: return "circle.fill"
        }
    }

    private var iconColor: Color {
        switch entry.action {
        case "created": return .wmsSuccess
        case "updated": return .wmsInfo
        case "deleted", "deactivated": return .wmsDestructive
        default: return .wmsTextSecondary
        }
    }

    private func formattedTimestamp(_ date: Date) -> String {
        let elapsed = -date.timeIntervalSinceNow
        if elapsed < 60 { return "just now" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))m ago" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))h ago" }
        if elapsed < 604800 { return "\(Int(elapsed / 86400))d ago" }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
