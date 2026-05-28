import Foundation

public protocol AuditRepository: Sendable {
    func insert(_ entry: AuditEntry) async throws
    func fetchAll(
        entityType: String?,
        startDate: Date?,
        endDate: Date?,
        action: String?
    ) async throws -> [AuditEntry]
}
