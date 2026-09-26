import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case warehouses
    case inventory
    case employees
    case transfers
    case reports
    case auditLog
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .warehouses: return "Warehouses"
        case .inventory: return "Inventory"
        case .employees: return "Employees"
        case .transfers: return "Transfers"
        case .reports: return "Reports"
        case .auditLog: return "Audit Log"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "gauge"
        case .warehouses: return "building.2"
        case .inventory: return "shippingbox"
        case .employees: return "person.2"
        case .transfers: return "arrow.triangle.2.circlepath"
        case .reports: return "chart.bar"
        case .auditLog: return "doc.text.magnifyingglass"
        case .settings: return "gearshape"
        }
    }
}

@Observable
final class AppRouter {
    var selectedSection: AppSection? = .dashboard
    var selectedWarehouseID: UUID?
    var selectedInventoryItemID: UUID?
    var selectedEmployeeID: UUID?
    var selectedTransferID: UUID?
    var showSearch = false

    func navigate(to section: AppSection) {
        selectedSection = section
    }
}
