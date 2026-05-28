import Foundation
import UserNotifications
import os

private let logger = Logger(subsystem: "com.warehouseos", category: "Notifications")

public final class NotificationManager: Sendable {
    public static let shared = NotificationManager()

    private var isAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    private init() {}

    public func requestPermission() {
        guard isAvailable else {
            logger.info("Skipping notification permission — no bundle identifier (running via swift run?)")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                logger.error("Notification permission error: \(error, privacy: .public)")
            }
            logger.info("Notification permission granted: \(granted)")
        }
    }

    public func postLowStockAlert(itemName: String, sku: String, currentQuantity: Int, threshold: Int, itemID: UUID) {
        guard isAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = "Low Stock Alert"
        content.body = "\(itemName) (SKU: \(sku)) is below minimum threshold. Current: \(currentQuantity), Threshold: \(threshold)."
        content.sound = .default
        content.categoryIdentifier = "LOW_STOCK"

        let request = UNNotificationRequest(
            identifier: "low-stock-\(itemID.uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to post low stock notification: \(error, privacy: .public)")
            }
        }
    }

    public func postTransferStatusAlert(transferCode: String, status: String) {
        guard isAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = "Transfer Update"
        content.body = "Transfer order \(transferCode) is now \(status)."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "transfer-\(transferCode)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to post transfer notification: \(error, privacy: .public)")
            }
        }
    }

    public func clearNotification(identifier: String) {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    public func clearAllNotifications() {
        guard isAvailable else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
