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
        var alerts: [AlertRecord] = try store.load([AlertRecord].self, file: file)
        alerts.append(alert)
        try store.save(alerts, file: file)
    }

    public func acknowledge(id: UUID) async throws {
        var alerts: [AlertRecord] = try store.load([AlertRecord].self, file: file)
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].isAcknowledged = true
        }
        try store.save(alerts, file: file)
    }
}
