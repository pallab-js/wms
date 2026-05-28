import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class AuditLogViewModel {
    var entries: [AuditEntry] = []
    var isLoading = false
    var errorMessage: String?
    var entityTypeFilter: String? {
        didSet { Task { await loadEntries() } }
    }
    var actionFilter: String? {
        didSet { Task { await loadEntries() } }
    }

    private let service: AuditLogService

    public init(service: AuditLogService) {
        self.service = service
    }

    public func loadEntries() async {
        isLoading = true
        errorMessage = nil
        do {
            entries = try await service.getEntries(
                entityType: entityTypeFilter,
                action: actionFilter
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
