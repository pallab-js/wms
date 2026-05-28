import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class TransferListViewModel {
    var transfers: [TransferOrder] = []
    var inventoryItems: [InventoryItem] = []
    var isLoading = false
    var errorMessage: String?

    private let transferService: TransferService
    private let warehouseService: WarehouseService
    private let inventoryService: InventoryService

    public init(transferService: TransferService, warehouseService: WarehouseService, inventoryService: InventoryService) {
        self.transferService = transferService
        self.warehouseService = warehouseService
        self.inventoryService = inventoryService
    }

    public func loadTransfers() async {
        isLoading = true
        errorMessage = nil
        do {
            transfers = try await transferService.getAllTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func loadInventoryItems() async {
        do {
            inventoryItems = try await inventoryService.getAllItems(forWarehouseID: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func createTransfer(
        sourceWarehouseID: UUID,
        destinationWarehouseID: UUID,
        lineItems: [TransferLineItem],
        notes: String
    ) async {
        do {
            _ = try await transferService.createTransfer(
                sourceWarehouseID: sourceWarehouseID,
                destinationWarehouseID: destinationWarehouseID,
                lineItems: lineItems,
                notes: notes
            )
            await loadTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func submitTransfer(id: UUID) async {
        do {
            try await transferService.submitTransfer(id: id)
            await loadTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func approveTransfer(id: UUID) async {
        do {
            try await transferService.approveTransfer(id: id)
            await loadTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func executeTransfer(id: UUID) async {
        do {
            try await transferService.executeTransfer(id: id)
            await loadTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func completeTransfer(id: UUID) async {
        do {
            try await transferService.completeTransfer(id: id)
            await loadTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func cancelTransfer(id: UUID) async {
        do {
            try await transferService.cancelTransfer(id: id)
            await loadTransfers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
