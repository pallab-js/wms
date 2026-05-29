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
                .createWarehouse, .editWarehouse, .deactivateWarehouse, .deleteWarehouse,
                .createEmployee, .editEmployee, .deactivateEmployee, .deleteEmployee,
                .recordStockIn, .recordStockOut, .adjustStock, .editInventoryItem, .deleteInventoryItem,
                .createTransfer, .submitTransfer, .approveTransfer, .executeTransfer,
                .completeTransfer, .cancelTransfer,
                .viewReports, .exportData
            ]
        case .inventoryClerk:
            return [
                .recordStockIn, .recordStockOut, .adjustStock, .editInventoryItem,
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
    case deactivateWarehouse
    case deleteWarehouse
    case createEmployee
    case editEmployee
    case deactivateEmployee
    case deleteEmployee
    case recordStockIn
    case recordStockOut
    case adjustStock
    case editInventoryItem
    case deleteInventoryItem
    case createTransfer
    case submitTransfer
    case approveTransfer
    case executeTransfer
    case completeTransfer
    case cancelTransfer
    case viewReports
    case exportData
    case manageSettings
}
