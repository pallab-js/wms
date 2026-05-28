import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class WarehouseListViewModel {
    var warehouses: [Warehouse] = []
    var isLoading = false
    var errorMessage: String?
    var validationErrors: [String] = []
    var selectedWarehouseID: UUID?

    private let service: WarehouseService

    public init(service: WarehouseService) {
        self.service = service
    }

    public func loadWarehouses() async {
        isLoading = true
        errorMessage = nil
        do {
            warehouses = try await service.getAllWarehouses()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func validateWarehouseForm(
        name: String, code: String, address: String, capacity: String
    ) -> Bool {
        let result = InputValidator.validateWarehouseForm(
            name: name, code: code, address: address, capacity: capacity
        )
        validationErrors = result.errors
        return result.isValid
    }

    public func createWarehouse(
        name: String,
        code: String,
        address: String,
        capacity: Int
    ) async {
        do {
            _ = try await service.createWarehouse(
                name: name, code: code, address: address, capacity: capacity
            )
            await loadWarehouses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateWarehouse(_ warehouse: Warehouse) async {
        do {
            try await service.updateWarehouse(warehouse)
            await loadWarehouses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deactivateWarehouse(id: UUID) async {
        do {
            try await service.deactivateWarehouse(id: id)
            await loadWarehouses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteWarehouse(id: UUID) async {
        do {
            try await service.deleteWarehouse(id: id)
            await loadWarehouses()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
