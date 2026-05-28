import Foundation
import os
import WMSCore

private let logger = Logger(subsystem: "com.warehouseos", category: "InventoryAlert")

public final class InventoryAlertService: Sendable {
    private let alertRepository: any AlertRepository
    private let alertCallback: (@Sendable (String, String) -> Void)?

    public init(
        alertRepository: any AlertRepository,
        alertCallback: (@Sendable (String, String) -> Void)? = nil
    ) {
        self.alertRepository = alertRepository
        self.alertCallback = alertCallback
    }

    public func checkThresholds(for item: InventoryItem) async {
        guard item.currentQuantity <= item.minimumThreshold,
              item.minimumThreshold > 0 else { return }

        let alert = AlertRecord(
            message: "\(item.name) (SKU: \(item.sku)) is below minimum threshold. Current: \(item.currentQuantity), Threshold: \(item.minimumThreshold)",
            severity: item.currentQuantity == 0 ? .critical : .warning,
            entityType: "InventoryItem",
            entityID: item.id
        )

        do {
            try await alertRepository.save(alert)
            alertCallback?("Low Stock Alert", alert.message)
        } catch {
            logger.error("Failed to save alert for \(item.sku, privacy: .public): \(error, privacy: .public)")
        }
    }

    public func getUnacknowledgedAlerts() async throws -> [AlertRecord] {
        try await alertRepository.fetchAll(unacknowledgedOnly: true)
    }

    public func acknowledgeAlert(id: UUID) async throws {
        try await alertRepository.acknowledge(id: id)
    }
}
