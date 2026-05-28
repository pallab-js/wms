import Foundation
import os
import WMSCore

private let logger = Logger(subsystem: "com.warehouseos", category: "AuditLogger")

public protocol AuditLogging: Sendable {
    func log(entityType: String, entityID: UUID, action: String, note: String?) async
}

public extension AuditLogging {
    func log(entityType: String, entityID: UUID, action: String) async {
        await log(entityType: entityType, entityID: entityID, action: action, note: nil)
    }
}

public final class AuditLogger: AuditLogging {
    private let repository: any AuditRepository
    private let userRole: String

    public init(repository: any AuditRepository, userRole: String = "Administrator") {
        self.repository = repository
        self.userRole = userRole
    }

    public func log(entityType: String, entityID: UUID, action: String, note: String? = nil) async {
        let entry = AuditEntry(
            entityType: entityType,
            entityID: entityID,
            action: action,
            userRole: userRole,
            note: note
        )
        do {
            try await repository.insert(entry)
        } catch {
            logger.error("Audit log failed for \(entityType) \(entityID, privacy: .public): \(error, privacy: .public)")
        }
    }
}

public struct NullAuditLogger: AuditLogging {
    public init() {}
    public func log(entityType: String, entityID: UUID, action: String, note: String?) async {}
}
