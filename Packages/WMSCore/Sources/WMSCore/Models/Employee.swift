import Foundation

public struct Employee: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var firstName: String
    public var lastName: String
    public var employeeCode: String
    public var jobTitle: String
    public var email: String
    public var phone: String
    public var warehouseIDs: [UUID]
    public var isActive: Bool
    public var hireDate: Date
    public var notes: String

    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        employeeCode: String,
        jobTitle: String,
        email: String,
        phone: String = "",
        warehouseIDs: [UUID] = [],
        isActive: Bool = true,
        hireDate: Date = Date(),
        notes: String = ""
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.employeeCode = employeeCode
        self.jobTitle = jobTitle
        self.email = email
        self.phone = phone
        self.warehouseIDs = warehouseIDs
        self.isActive = isActive
        self.hireDate = hireDate
        self.notes = notes
    }

    public var fullName: String {
        "\(firstName) \(lastName)"
    }
}
