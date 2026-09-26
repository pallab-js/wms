import Foundation
import WMSCore
import WMSServices

public enum WarehouseSortOrder: String, CaseIterable, Identifiable, Sendable {
    case name
    case code
    case utilisation
    case value

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .name: return "Name"
        case .code: return "Code"
        case .utilisation: return "Utilisation"
        case .value: return "Inventory Value"
        }
    }

    public var systemImage: String {
        switch self {
        case .name: return "textformat"
        case .code: return "number"
        case .utilisation: return "gauge"
        case .value: return "dollarsign"
        }
    }
}

public enum WarehouseStatusFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case active
    case inactive

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .inactive: return "Inactive"
        }
    }
}

@Observable
@MainActor
public final class WarehouseListViewModel {
    var warehouses: [Warehouse] = []
    var stats: [UUID: WarehouseStats] = [:]
    var isLoading = false
    var errorMessage: String?
    var validationErrors: [String] = []
    var selectedWarehouseID: UUID?
    public var searchText = ""
    public var sortOrder: WarehouseSortOrder = .name
    public var statusFilter: WarehouseStatusFilter = .all

    private let service: WarehouseService
    private let statsService: WarehouseStatsService

    public init(service: WarehouseService, statsService: WarehouseStatsService) {
        self.service = service
        self.statsService = statsService
    }

    public func loadWarehouses() async {
        isLoading = true
        errorMessage = nil
        do {
            async let warehousesTask = service.getAllWarehouses()
            async let statsTask = statsService.getAllStats()
            warehouses = try await warehousesTask
            stats = Dictionary(
                uniqueKeysWithValues: try await statsTask.map { ($0.warehouseID, $0) }
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var filteredWarehouses: [Warehouse] {
        var result = warehouses

        switch statusFilter {
        case .all: break
        case .active: result = result.filter(\.isActive)
        case .inactive: result = result.filter { !$0.isActive }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                    || $0.code.localizedCaseInsensitiveContains(query)
            }
        }

        switch sortOrder {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .code:
            result.sort { $0.code.localizedCaseInsensitiveCompare($1.code) == .orderedAscending }
        case .utilisation:
            result.sort { utilisation(of: $0) > utilisation(of: $1) }
        case .value:
            result.sort { (stats[$0.id]?.totalValue ?? 0) > (stats[$1.id]?.totalValue ?? 0) }
        }

        return result
    }

    public struct KPI: Sendable, Equatable {
        public let warehouseCount: Int
        public let activeCount: Int
        public let unitCount: Int
        public let totalValue: Double
        public let averageUtilisation: Double

        public init(
            warehouseCount: Int,
            activeCount: Int,
            unitCount: Int,
            totalValue: Double,
            averageUtilisation: Double
        ) {
            self.warehouseCount = warehouseCount
            self.activeCount = activeCount
            self.unitCount = unitCount
            self.totalValue = totalValue
            self.averageUtilisation = averageUtilisation
        }
    }

    public var kpi: KPI {
        let visible = filteredWarehouses
        let visibleStats = visible.compactMap { stats[$0.id] }
        let utilisations = visibleStats.map(\.utilisation)
        let averageUtilisation = utilisations.isEmpty
            ? 0.0
            : utilisations.reduce(0, +) / Double(utilisations.count)
        return KPI(
            warehouseCount: visible.count,
            activeCount: visible.filter(\.isActive).count,
            unitCount: visibleStats.reduce(0) { $0 + $1.unitCount },
            totalValue: visibleStats.reduce(0.0) { $0 + $1.totalValue },
            averageUtilisation: averageUtilisation
        )
    }

    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || statusFilter != .all
    }

    func stats(for warehouse: Warehouse) -> WarehouseStats? {
        stats[warehouse.id]
    }

    func clearFilters() {
        searchText = ""
        statusFilter = .all
    }

    private func utilisation(of warehouse: Warehouse) -> Double {
        stats[warehouse.id]?.utilisation ?? 0
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
