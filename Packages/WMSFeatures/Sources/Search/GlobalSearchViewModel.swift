import Foundation
import WMSCore
import WMSServices

@Observable
@MainActor
public final class GlobalSearchViewModel {
    var query: String = "" {
        didSet {
            Task { await performSearch() }
        }
    }
    var warehouseResults: [Warehouse] = []
    var inventoryResults: [InventoryItem] = []
    var employeeResults: [Employee] = []
    var isSearching = false

    var hasResults: Bool {
        !warehouseResults.isEmpty || !inventoryResults.isEmpty || !employeeResults.isEmpty
    }

    private let warehouseService: WarehouseService
    private let inventoryService: InventoryService
    private let employeeService: EmployeeService
    private var searchTask: Task<Void, Never>?

    public init(
        warehouseService: WarehouseService,
        inventoryService: InventoryService,
        employeeService: EmployeeService
    ) {
        self.warehouseService = warehouseService
        self.inventoryService = inventoryService
        self.employeeService = employeeService
    }

    public func performSearch() async {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            clearResults()
            return
        }

        searchTask = Task {
            isSearching = true
            let lowerQuery = trimmed.lowercased()

            async let warehousesTask = searchWarehouses(query: lowerQuery)
            async let inventoryTask = searchInventory(query: lowerQuery)
            async let employeesTask = searchEmployees(query: lowerQuery)

            warehouseResults = await warehousesTask
            inventoryResults = await inventoryTask
            employeeResults = await employeesTask

            isSearching = false
        }
    }

    public func clearResults() {
        warehouseResults = []
        inventoryResults = []
        employeeResults = []
    }

    private func searchWarehouses(query: String) async -> [Warehouse] {
        guard !Task.isCancelled else { return [] }
        do {
            let all = try await warehouseService.getAllWarehouses()
            return all.filter {
                $0.name.lowercased().contains(query) ||
                $0.code.lowercased().contains(query) ||
                $0.address.lowercased().contains(query)
            }
        } catch {
            return []
        }
    }

    private func searchInventory(query: String) async -> [InventoryItem] {
        guard !Task.isCancelled else { return [] }
        do {
            let all = try await inventoryService.getAllItems()
            return all.filter {
                $0.name.lowercased().contains(query) ||
                $0.sku.lowercased().contains(query) ||
                $0.category.lowercased().contains(query)
            }
        } catch {
            return []
        }
    }

    private func searchEmployees(query: String) async -> [Employee] {
        guard !Task.isCancelled else { return [] }
        do {
            let all = try await employeeService.getAllEmployees()
            return all.filter {
                $0.fullName.lowercased().contains(query) ||
                $0.employeeCode.lowercased().contains(query) ||
                $0.email.lowercased().contains(query) ||
                $0.jobTitle.lowercased().contains(query)
            }
        } catch {
            return []
        }
    }
}
