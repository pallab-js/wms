import Foundation

public struct AlertRecord: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var message: String
    public var severity: AlertSeverity
    public var entityType: String
    public var entityID: UUID
    public var isAcknowledged: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        message: String,
        severity: AlertSeverity,
        entityType: String,
        entityID: UUID,
        isAcknowledged: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.message = message
        self.severity = severity
        self.entityType = entityType
        self.entityID = entityID
        self.isAcknowledged = isAcknowledged
        self.createdAt = createdAt
    }
}

public enum AlertSeverity: String, Codable, Sendable {
    case info
    case warning
    case critical
}
