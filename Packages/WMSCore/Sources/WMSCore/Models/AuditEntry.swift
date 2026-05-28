import Foundation

public struct AuditEntry: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var timestamp: Date
    public var entityType: String
    public var entityID: UUID
    public var action: String
    public var changedFields: Data?
    public var userRole: String
    public var note: String?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        entityType: String,
        entityID: UUID,
        action: String,
        changedFields: Data? = nil,
        userRole: String,
        note: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.entityType = entityType
        self.entityID = entityID
        self.action = action
        self.changedFields = changedFields
        self.userRole = userRole
        self.note = note
    }
}
