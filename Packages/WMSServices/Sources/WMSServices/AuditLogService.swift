import Foundation
import WMSCore

public final class AuditLogService: Sendable {
    private let repository: any AuditRepository

    public init(repository: any AuditRepository) {
        self.repository = repository
    }

    public func getEntries(
        entityType: String? = nil,
        action: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) async throws -> [AuditEntry] {
        try await repository.fetchAll(
            entityType: entityType,
            startDate: startDate,
            endDate: endDate,
            action: action
        )
    }
}
