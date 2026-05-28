import XCTest
import Foundation
@testable import WMSCore
@testable import WMSServices

final class MockInventoryItemRepository: InventoryItemRepository {
    var items: [InventoryItem] = []
    var shouldThrow = false

    func fetchAll(forWarehouseID warehouseID: UUID?) async throws -> [InventoryItem] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let warehouseID {
            return items.filter { $0.warehouseID == warehouseID }
        }
        return items
    }

    func fetch(byID id: UUID) async throws -> InventoryItem? {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return items.first { $0.id == id }
    }

    func fetch(bySKU sku: String, inWarehouseID warehouseID: UUID) async throws -> InventoryItem? {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return items.first { $0.sku == sku && $0.warehouseID == warehouseID }
    }

    func save(_ item: InventoryItem) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
    }

    func saveWithMovement(_ item: InventoryItem, movement: StockMovement) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
    }

    func delete(id: UUID) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        items.removeAll { $0.id == id }
    }
}

final class MockStockMovementRepository: StockMovementRepository {
    var movements: [StockMovement] = []
    var shouldThrow = false

    func fetchAll(forItemID itemID: UUID?) async throws -> [StockMovement] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let itemID {
            return movements.filter { $0.itemID == itemID }
        }
        return movements
    }

    func fetchRecent(limit: Int) async throws -> [StockMovement] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return Array(movements.sorted { $0.recordedAt > $1.recordedAt }.prefix(limit))
    }

    func save(_ movement: StockMovement) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        movements.append(movement)
    }
}

final class MockTransferOrderRepository: TransferOrderRepository {
    var orders: [TransferOrder] = []
    var shouldThrow = false

    func fetchAll() async throws -> [TransferOrder] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return orders
    }

    func fetch(byID id: UUID) async throws -> TransferOrder? {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return orders.first { $0.id == id }
    }

    func save(_ order: TransferOrder) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
        } else {
            orders.append(order)
        }
    }

    func delete(id: UUID) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        orders.removeAll { $0.id == id }
    }
}

final class MockEmployeeRepository: EmployeeRepository {
    var employees: [Employee] = []
    var shouldThrow = false

    func fetchAll() async throws -> [Employee] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return employees
    }

    func fetch(byID id: UUID) async throws -> Employee? {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return employees.first { $0.id == id }
    }

    func fetch(byWarehouseID warehouseID: UUID) async throws -> [Employee] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        return employees.filter { $0.warehouseIDs.contains(warehouseID) }
    }

    func save(_ employee: Employee) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let index = employees.firstIndex(where: { $0.id == employee.id }) {
            employees[index] = employee
        } else {
            employees.append(employee)
        }
    }

    func delete(id: UUID) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        employees.removeAll { $0.id == id }
    }
}

final class MockAuditRepository: AuditRepository {
    var entries: [AuditEntry] = []
    var shouldThrow = false

    func insert(_ entry: AuditEntry) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        entries.append(entry)
    }

    func fetchAll(
        entityType: String?,
        startDate: Date?,
        endDate: Date?,
        action: String?
    ) async throws -> [AuditEntry] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        var result = entries
        if let entityType { result = result.filter { $0.entityType == entityType } }
        if let startDate { result = result.filter { $0.timestamp >= startDate } }
        if let endDate { result = result.filter { $0.timestamp <= endDate } }
        if let action { result = result.filter { $0.action == action } }
        return result.sorted { $0.timestamp > $1.timestamp }
    }
}

final class MockAlertRepository: AlertRepository {
    var alerts: [AlertRecord] = []
    var shouldThrow = false

    func fetchAll(unacknowledgedOnly: Bool) async throws -> [AlertRecord] {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if unacknowledgedOnly {
            return alerts.filter { !$0.isAcknowledged }
        }
        return alerts
    }

    func save(_ alert: AlertRecord) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        alerts.append(alert)
    }

    func acknowledge(id: UUID) async throws {
        if shouldThrow { throw WMSError.persistenceFailed("Mock error") }
        if let index = alerts.firstIndex(where: { $0.id == id }) {
            alerts[index].isAcknowledged = true
        }
    }
}
