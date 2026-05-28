import Foundation

public enum UserRole: String, Codable, CaseIterable, Sendable {
    case administrator
    case warehouseManager
    case inventoryClerk
    case analyst

    public var label: String {
        switch self {
        case .administrator: return "Administrator"
        case .warehouseManager: return "Warehouse Manager"
        case .inventoryClerk: return "Inventory Clerk"
        case .analyst: return "Analyst"
        }
    }

    public var permissions: Set<Permission> {
        switch self {
        case .administrator:
            return Set(Permission.allCases)
        case .warehouseManager:
            return [
                .createWarehouse, .editWarehouse,
                .createEmployee, .editEmployee,
                .recordStockIn, .recordStockOut, .adjustStock,
                .createTransfer, .approveTransfer,
                .viewReports, .exportData
            ]
        case .inventoryClerk:
            return [
                .recordStockIn, .recordStockOut, .adjustStock,
                .viewReports
            ]
        case .analyst:
            return [
                .viewReports, .exportData
            ]
        }
    }
}

public enum Permission: String, Codable, CaseIterable, Sendable {
    case createWarehouse
    case editWarehouse
    case deleteWarehouse
    case createEmployee
    case editEmployee
    case deactivateEmployee
    case recordStockIn
    case recordStockOut
    case adjustStock
    case createTransfer
    case approveTransfer
    case viewReports
    case exportData
    case manageSettings
}
