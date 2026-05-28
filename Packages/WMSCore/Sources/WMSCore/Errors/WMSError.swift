import Foundation

public enum WMSError: LocalizedError, Equatable {
    case duplicateWarehouseCode(String)
    case duplicateSKU(String)
    case duplicateEmployeeCode(String)
    case warehouseNotFound
    case inventoryItemNotFound
    case employeeNotFound
    case transferNotFound
    case insufficientStock(itemName: String, available: Int, requested: Int)
    case transferAlreadyCompleted
    case invalidTransferState(from: String, to: String)
    case persistenceFailed(String)
    case validationError(String)
    case unauthorised
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .duplicateWarehouseCode(let code):
            return "A warehouse with code '\(code)' already exists."
        case .duplicateSKU(let sku):
            return "An inventory item with SKU '\(sku)' already exists."
        case .duplicateEmployeeCode(let code):
            return "An employee with code '\(code)' already exists."
        case .warehouseNotFound:
            return "The requested warehouse could not be found."
        case .inventoryItemNotFound:
            return "The requested inventory item could not be found."
        case .employeeNotFound:
            return "The requested employee could not be found."
        case .transferNotFound:
            return "The requested transfer order could not be found."
        case .insufficientStock(let name, let available, let requested):
            return "Insufficient stock for \(name). Available: \(available), Requested: \(requested)."
        case .transferAlreadyCompleted:
            return "This transfer order has already been completed."
        case .invalidTransferState(let from, let to):
            return "Cannot transition transfer from '\(from)' to '\(to)'."
        case .persistenceFailed(let detail):
            return "Data operation failed: \(detail)"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .unauthorised:
            return "You do not have permission to perform this action."
        case .unknown(let detail):
            return "An unexpected error occurred: \(detail)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .duplicateWarehouseCode:
            return "Please choose a different warehouse code."
        case .duplicateSKU:
            return "Please choose a different SKU."
        case .duplicateEmployeeCode:
            return "Please choose a different employee code."
        case .insufficientStock:
            return "Reduce the requested quantity or record a stock-in first."
        case .invalidTransferState:
            return "Check the current transfer status before attempting this action."
        case .persistenceFailed:
            return "Please try again. If the problem persists, restart the application."
        case .validationError:
            return "Please correct the input and try again."
        case .unauthorised:
            return "Contact your administrator to request the required permissions."
        default:
            return nil
        }
    }
}
