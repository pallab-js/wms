import Foundation

public struct ValidationResult: Equatable {
    public let isValid: Bool
    public let errors: [String]

    public static let valid = ValidationResult(isValid: true, errors: [])

    public init(isValid: Bool, errors: [String]) {
        self.isValid = isValid
        self.errors = errors
    }
}

public struct InputValidator {
    /// Upper bound for any count-like value (quantity, threshold, capacity).
    /// Keeps later arithmetic safely away from `Int` overflow.
    public static let maxCount = 1_000_000_000
    /// Upper bound for monetary values so totals stay finite and JSON-encodable.
    public static let maxAmount = 1_000_000_000.0

    public static func validateNotEmpty(_ value: String, field: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ValidationResult(isValid: false, errors: ["\(field) cannot be empty."])
        }
        return .valid
    }

    public static func validatePositiveInt(_ value: String, field: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let intValue = Int(trimmed) else {
            return ValidationResult(isValid: false, errors: ["\(field) must be a whole number."])
        }
        guard intValue > 0 else {
            return ValidationResult(isValid: false, errors: ["\(field) must be a positive number."])
        }
        guard intValue <= maxCount else {
            return ValidationResult(isValid: false, errors: ["\(field) must be \(maxCount) or less."])
        }
        return .valid
    }

    public static func validateNonNegativeInt(_ value: String, field: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let intValue = Int(trimmed) else {
            return ValidationResult(isValid: false, errors: ["\(field) must be a whole number."])
        }
        guard intValue >= 0 else {
            return ValidationResult(isValid: false, errors: ["\(field) must be zero or more."])
        }
        guard intValue <= maxCount else {
            return ValidationResult(isValid: false, errors: ["\(field) must be \(maxCount) or less."])
        }
        return .valid
    }

    public static func validateNonNegativeDouble(_ value: String, field: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let doubleValue = Double(trimmed), doubleValue.isFinite else {
            return ValidationResult(isValid: false, errors: ["\(field) must be a number."])
        }
        guard doubleValue >= 0 else {
            return ValidationResult(isValid: false, errors: ["\(field) must be zero or more."])
        }
        guard doubleValue <= maxAmount else {
            return ValidationResult(isValid: false, errors: ["\(field) must be \(maxAmount) or less."])
        }
        return .valid
    }

    public static func validateEmail(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ValidationResult(isValid: false, errors: ["Email cannot be empty."])
        }
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        if trimmed.range(of: emailRegex, options: .regularExpression) != nil {
            return .valid
        }
        return ValidationResult(isValid: false, errors: ["Please enter a valid email address."])
    }

    public static func validateWarehouseForm(
        name: String, code: String, address: String, capacity: String
    ) -> ValidationResult {
        var errors: [String] = []

        let nameResult = validateNotEmpty(name, field: "Name")
        if !nameResult.isValid { errors.append(contentsOf: nameResult.errors) }

        let codeResult = validateNotEmpty(code, field: "Code")
        if !codeResult.isValid { errors.append(contentsOf: codeResult.errors) }

        let capacityResult = validatePositiveInt(capacity, field: "Capacity")
        if !capacityResult.isValid { errors.append(contentsOf: capacityResult.errors) }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    public static func validateInventoryItemForm(
        sku: String, name: String, quantity: String, threshold: String, cost: String
    ) -> ValidationResult {
        var errors: [String] = []

        let skuResult = validateNotEmpty(sku, field: "SKU")
        if !skuResult.isValid { errors.append(contentsOf: skuResult.errors) }

        let nameResult = validateNotEmpty(name, field: "Name")
        if !nameResult.isValid { errors.append(contentsOf: nameResult.errors) }

        let qtyResult = validateNonNegativeInt(quantity, field: "Quantity")
        if !qtyResult.isValid { errors.append(contentsOf: qtyResult.errors) }

        let thresholdResult = validateNonNegativeInt(threshold, field: "Threshold")
        if !thresholdResult.isValid { errors.append(contentsOf: thresholdResult.errors) }

        let costResult = validateNonNegativeDouble(cost, field: "Unit cost")
        if !costResult.isValid { errors.append(contentsOf: costResult.errors) }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    public static func validateEmployeeForm(
        firstName: String, lastName: String, employeeCode: String, email: String
    ) -> ValidationResult {
        var errors: [String] = []

        let firstResult = validateNotEmpty(firstName, field: "First name")
        if !firstResult.isValid { errors.append(contentsOf: firstResult.errors) }

        let lastResult = validateNotEmpty(lastName, field: "Last name")
        if !lastResult.isValid { errors.append(contentsOf: lastResult.errors) }

        let codeResult = validateNotEmpty(employeeCode, field: "Employee code")
        if !codeResult.isValid { errors.append(contentsOf: codeResult.errors) }

        let emailResult = validateEmail(email)
        if !emailResult.isValid { errors.append(contentsOf: emailResult.errors) }

        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }

    /// Throwing wrappers for service-layer use
    public static func requireNotEmpty(_ value: String, field: String) throws {
        let result = validateNotEmpty(value, field: field)
        if !result.isValid {
            throw WMSError.validationError(result.errors.joined(separator: ", "))
        }
    }

    public static func requirePositiveInt(_ value: String, field: String) throws -> Int {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let result = validatePositiveInt(trimmed, field: field)
        if !result.isValid {
            throw WMSError.validationError(result.errors.joined(separator: ", "))
        }
        guard let intVal = Int(trimmed) else {
            throw WMSError.validationError("\(field) must be a valid integer.")
        }
        return intVal
    }

    public static func requirePositiveInt(_ value: Int, field: String) throws {
        guard value > 0 else {
            throw WMSError.validationError("\(field) must be greater than zero.")
        }
        guard value <= maxCount else {
            throw WMSError.validationError("\(field) must be \(maxCount) or less.")
        }
    }

    public static func requireNonNegativeInt(_ value: Int, field: String) throws {
        guard value >= 0 else {
            throw WMSError.validationError("\(field) must be zero or more.")
        }
        guard value <= maxCount else {
            throw WMSError.validationError("\(field) must be \(maxCount) or less.")
        }
    }

    public static func requireNonNegativeDouble(_ value: Double, field: String) throws {
        guard value.isFinite, value >= 0, value <= maxAmount else {
            throw WMSError.validationError("\(field) must be a number between 0 and \(maxAmount).")
        }
    }

    public static func requireValidEmail(_ value: String) throws {
        let result = validateEmail(value)
        if !result.isValid {
            throw WMSError.validationError(result.errors.joined(separator: ", "))
        }
    }
}
