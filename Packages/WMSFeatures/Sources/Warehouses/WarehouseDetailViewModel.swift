import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class WarehouseDetailViewModel {
    var warehouse: Warehouse
    var stats: WarehouseStats?
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?

    private let service: WarehouseService
    private let statsService: WarehouseStatsService

    public init(
        warehouse: Warehouse,
        service: WarehouseService,
        statsService: WarehouseStatsService
    ) {
        self.warehouse = warehouse
        self.service = service
        self.statsService = statsService
    }

    public func loadStats() async {
        isLoading = stats == nil
        errorMessage = nil
        do {
            stats = try await statsService.getStats(forWarehouseID: warehouse.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func applyUpdate(_ updated: Warehouse) {
        warehouse = updated
    }

    @discardableResult
    public func toggleActive() async -> Bool {
        do {
            if warehouse.isActive {
                try await service.deactivateWarehouse(id: warehouse.id)
                warehouse.isActive = false
                successMessage = "Warehouse deactivated"
            } else {
                try await service.activateWarehouse(id: warehouse.id)
                warehouse.isActive = true
                successMessage = "Warehouse activated"
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    public func deleteWarehouse() async -> Bool {
        do {
            try await service.deleteWarehouse(id: warehouse.id)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
