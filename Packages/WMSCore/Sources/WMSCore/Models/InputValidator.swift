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
    public static func validateNotEmpty(_ value: String, field: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ValidationResult(isValid: false, errors: ["\(field) cannot be empty."])
        }
        return .valid
    }

    public static func validatePositiveInt(_ value: String, field: String) -> ValidationResult {
        guard let intValue = Int(value), intValue > 0 else {
            return ValidationResult(isValid: false, errors: ["\(field) must be a positive number."])
        }
        return .valid
    }

    public static func validateNonNegativeInt(_ value: String, field: String) -> ValidationResult {
        guard let intValue = Int(value), intValue >= 0 else {
            return ValidationResult(isValid: false, errors: ["\(field) must be zero or more."])
        }
        return .valid
    }

    public static func validatePositiveDouble(_ value: String, field: String) -> ValidationResult {
        guard let doubleValue = Double(value), doubleValue >= 0 else {
            return ValidationResult(isValid: false, errors: ["\(field) must be a valid positive number."])
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

        let costResult = validatePositiveDouble(cost, field: "Unit cost")
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

        let emailResult = validateNotEmpty(email, field: "Email")
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
        let result = validatePositiveInt(value, field: field)
        if !result.isValid {
            throw WMSError.validationError(result.errors.joined(separator: ", "))
        }
        return Int(value)!
    }
}
