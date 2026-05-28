import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class InventoryListViewModel {
    var items: [InventoryItem] = []
    var isLoading = false
    var errorMessage: String?
    var validationErrors: [String] = []
    var selectedWarehouseID: UUID?

    private let service: InventoryService

    public init(service: InventoryService) {
        self.service = service
    }

    public func loadItems() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await service.getAllItems(forWarehouseID: selectedWarehouseID)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func filterByWarehouse(_ warehouseID: UUID?) async {
        selectedWarehouseID = warehouseID
        await loadItems()
    }

    public func validateInventoryItemForm(
        sku: String, name: String, quantity: String, threshold: String, cost: String
    ) -> Bool {
        let result = InputValidator.validateInventoryItemForm(
            sku: sku, name: name, quantity: quantity, threshold: threshold, cost: cost
        )
        validationErrors = result.errors
        return result.isValid
    }

    public func createItem(
        sku: String,
        name: String,
        description: String,
        category: String,
        unitOfMeasure: String,
        currentQuantity: Int,
        minimumThreshold: Int,
        unitCost: Double,
        warehouseID: UUID
    ) async {
        do {
            _ = try await service.createItem(
                sku: sku, name: name, description: description,
                category: category, unitOfMeasure: unitOfMeasure,
                currentQuantity: currentQuantity, minimumThreshold: minimumThreshold,
                unitCost: unitCost, warehouseID: warehouseID
            )
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateItem(_ item: InventoryItem) async {
        do {
            try await service.updateItem(item)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteItem(id: UUID) async {
        do {
            try await service.deleteItem(id: id)
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func recordMovement(
        itemID: UUID,
        type: MovementType,
        quantity: Int,
        note: String?,
        referenceNumber: String?
    ) async {
        do {
            _ = try await service.recordMovement(
                itemID: itemID,
                type: type,
                quantity: quantity,
                note: note,
                referenceNumber: referenceNumber
            )
            await loadItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
