import Foundation
import WMSCore

public final class FileAlertRepository: AlertRepository {
    private let store: WMSDataStore
    private let file = "alert_records.json"

    public init(store: WMSDataStore) {
        self.store = store
    }

    public func fetchAll(unacknowledgedOnly: Bool) async throws -> [AlertRecord] {
        var alerts: [AlertRecord] = try store.load([AlertRecord].self, file: file)
        if unacknowledgedOnly {
            alerts = alerts.filter { !$0.isAcknowledged }
        }
        return alerts.sorted { $0.createdAt > $1.createdAt }
    }

    public func save(_ alert: AlertRecord) async throws {
        try store.atomicWrite { store in
            var alerts: [AlertRecord] = try store.loadUnsafe([AlertRecord].self, file: self.file)
            alerts.append(alert)
            try store.saveUnsafe(alerts, file: self.file)
        }
    }

    public func acknowledge(id: UUID) async throws {
        try store.atomicWrite { store in
            var alerts: [AlertRecord] = try store.loadUnsafe([AlertRecord].self, file: self.file)
            guard let index = alerts.firstIndex(where: { $0.id == id }) else {
                throw WMSError.validationError("Alert not found.")
            }
            alerts[index].isAcknowledged = true
            try store.saveUnsafe(alerts, file: self.file)
        }
    }
}
