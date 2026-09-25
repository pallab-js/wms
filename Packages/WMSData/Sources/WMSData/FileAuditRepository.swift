import Foundation
import WMSCore

public final class FileAuditRepository: AuditRepository {
    private let store: WMSDataStore
    private let file = "audit_entries.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func insert(_ entry: AuditEntry) async throws {
        try store.atomicWrite { store in
            var entries: [AuditEntry] = try store.loadUnsafe([AuditEntry].self, file: self.file)
            entries.append(entry)
            try store.saveUnsafe(entries, file: self.file)
        }
    }

    public func fetchAll(
        entityType: String?,
        startDate: Date?,
        endDate: Date?,
        action: String?
    ) async throws -> [AuditEntry] {
        var entries: [AuditEntry] = try store.load([AuditEntry].self, file: file)

        if let entityType {
            entries = entries.filter { $0.entityType == entityType }
        }
        if let startDate {
            entries = entries.filter { $0.timestamp >= startDate }
        }
        if let endDate {
            entries = entries.filter { $0.timestamp <= endDate }
        }
        if let action {
            entries = entries.filter { $0.action == action }
        }

        return entries.sorted { $0.timestamp > $1.timestamp }
    }
}
