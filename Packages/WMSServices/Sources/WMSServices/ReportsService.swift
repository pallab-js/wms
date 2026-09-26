import Foundation
import WMSCore

public final class ReportsService: Sendable {
    private let warehouseRepository: any WarehouseRepository
    private let inventoryService: InventoryService
    private let movementService: StockMovementService
    private let transferService: TransferService

    public init(
        warehouseRepository: any WarehouseRepository,
        inventoryService: InventoryService,
        movementService: StockMovementService,
        transferService: TransferService
    ) {
        self.warehouseRepository = warehouseRepository
        self.inventoryService = inventoryService
        self.movementService = movementService
        self.transferService = transferService
    }

    public func getReports() async throws -> ReportsData {
        async let warehousesTask = warehouseRepository.fetchAll()
        async let itemsTask = inventoryService.getAllItems(forWarehouseID: nil)
        async let movementsTask = movementService.getAllMovements()
        async let transfersTask = transferService.getAllTransfers()

        let warehouses = try await warehousesTask
        let items = try await itemsTask
        let movements = try await movementsTask
        let transfers = try await transfersTask

        let warehouseNames = Dictionary(uniqueKeysWithValues: warehouses.map { ($0.id, $0.name) })

        var unitsByWarehouse: [UUID: Int] = [:]
        var skusByWarehouse: [UUID: Int] = [:]
        var valueByWarehouse: [UUID: Double] = [:]
        var unitsByCategory: [String: Int] = [:]
        var skusByCategory: [String: Int] = [:]
        var valueByCategory: [String: Double] = [:]

        for item in items {
            let value = Double(item.currentQuantity) * item.unitCost
            unitsByWarehouse[item.warehouseID, default: 0] += item.currentQuantity
            skusByWarehouse[item.warehouseID, default: 0] += 1
            valueByWarehouse[item.warehouseID, default: 0] += value

            let category = item.category.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = category.isEmpty ? "Uncategorised" : category
            unitsByCategory[key, default: 0] += item.currentQuantity
            skusByCategory[key, default: 0] += 1
            valueByCategory[key, default: 0] += value
        }

        let valuationByWarehouse = valueByWarehouse.map { warehouseID, totalValue in
            WarehouseValuation(
                warehouseID: warehouseID,
                warehouseName: warehouseNames[warehouseID] ?? "Unknown Warehouse",
                skuCount: skusByWarehouse[warehouseID, default: 0],
                unitCount: unitsByWarehouse[warehouseID, default: 0],
                totalValue: totalValue
            )
        }
        .sorted { $0.totalValue > $1.totalValue }

        let valuationByCategory = valueByCategory.map { category, totalValue in
            CategoryValuation(
                category: category,
                skuCount: skusByCategory[category, default: 0],
                unitCount: unitsByCategory[category, default: 0],
                totalValue: totalValue
            )
        }
        .sorted { $0.totalValue > $1.totalValue }

        let movementTypes: [MovementType] = [.stockIn, .stockOut, .adjustment]
        let movementSummary: [MovementSummary] = movementTypes.map { type in
            let matching = movements.filter { $0.movementType == type }
            return MovementSummary(
                type: type,
                count: matching.count,
                totalQuantity: matching.reduce(0) { $0 + $1.quantity }
            )
        }

        let statuses: [TransferStatus] = [.draft, .submitted, .approved, .inTransit, .completed, .cancelled]
        let transferSummary: [TransferSummary] = statuses.map { status in
            TransferSummary(status: status, count: transfers.filter { $0.status == status }.count)
        }

        let lowStockItems = items
            .filter { $0.isActive && $0.minimumThreshold > 0 && $0.currentQuantity <= $0.minimumThreshold }
            .sorted { $0.currentQuantity < $1.currentQuantity }

        return ReportsData(
            valuationByWarehouse: valuationByWarehouse,
            valuationByCategory: valuationByCategory,
            movementSummary: movementSummary,
            transferSummary: transferSummary,
            lowStockItems: lowStockItems,
            warehouseNames: warehouseNames,
            generatedAt: Date()
        )
    }
}

public struct WarehouseValuation: Sendable, Equatable {
    public let warehouseID: UUID
    public let warehouseName: String
    public let skuCount: Int
    public let unitCount: Int
    public let totalValue: Double

    public init(warehouseID: UUID, warehouseName: String, skuCount: Int, unitCount: Int, totalValue: Double) {
        self.warehouseID = warehouseID
        self.warehouseName = warehouseName
        self.skuCount = skuCount
        self.unitCount = unitCount
        self.totalValue = totalValue
    }
}

public struct CategoryValuation: Sendable, Equatable {
    public let category: String
    public let skuCount: Int
    public let unitCount: Int
    public let totalValue: Double

    public init(category: String, skuCount: Int, unitCount: Int, totalValue: Double) {
        self.category = category
        self.skuCount = skuCount
        self.unitCount = unitCount
        self.totalValue = totalValue
    }
}

public struct MovementSummary: Sendable, Equatable {
    public let type: MovementType
    public let count: Int
    public let totalQuantity: Int

    public init(type: MovementType, count: Int, totalQuantity: Int) {
        self.type = type
        self.count = count
        self.totalQuantity = totalQuantity
    }

    public var label: String {
        switch type {
        case .stockIn: return "Stock In"
        case .stockOut: return "Stock Out"
        case .adjustment: return "Adjustment"
        }
    }
}

public struct TransferSummary: Sendable, Equatable {
    public let status: TransferStatus
    public let count: Int

    public init(status: TransferStatus, count: Int) {
        self.status = status
        self.count = count
    }

    public var label: String {
        switch status {
        case .draft: return "Draft"
        case .submitted: return "Submitted"
        case .approved: return "Approved"
        case .inTransit: return "In Transit"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }
}

public struct ReportsData: Sendable, Equatable {
    public let valuationByWarehouse: [WarehouseValuation]
    public let valuationByCategory: [CategoryValuation]
    public let movementSummary: [MovementSummary]
    public let transferSummary: [TransferSummary]
    public let lowStockItems: [InventoryItem]
    public let warehouseNames: [UUID: String]
    public let generatedAt: Date

    public init(
        valuationByWarehouse: [WarehouseValuation],
        valuationByCategory: [CategoryValuation],
        movementSummary: [MovementSummary],
        transferSummary: [TransferSummary],
        lowStockItems: [InventoryItem],
        warehouseNames: [UUID: String],
        generatedAt: Date
    ) {
        self.valuationByWarehouse = valuationByWarehouse
        self.valuationByCategory = valuationByCategory
        self.movementSummary = movementSummary
        self.transferSummary = transferSummary
        self.lowStockItems = lowStockItems
        self.warehouseNames = warehouseNames
        self.generatedAt = generatedAt
    }
}

public extension ReportsData {
    var csv: String {
        var lines: [String] = []
        lines.append("WarehouseOS Reports,Generated,\(generatedAt.ISO8601Format())")
        lines.append("")
        lines.append("Inventory Valuation by Warehouse")
        lines.append("Warehouse,SKUs,Units,Value")
        for row in valuationByWarehouse {
            lines.append([
                escape(row.warehouseName),
                String(row.skuCount),
                String(row.unitCount),
                money(row.totalValue)
            ].joined(separator: ","))
        }
        lines.append("")
        lines.append("Valuation by Category")
        lines.append("Category,SKUs,Units,Value")
        for row in valuationByCategory {
            lines.append([
                escape(row.category),
                String(row.skuCount),
                String(row.unitCount),
                money(row.totalValue)
            ].joined(separator: ","))
        }
        lines.append("")
        lines.append("Stock Movement Activity")
        lines.append("Type,Movements,Total Quantity")
        for row in movementSummary {
            lines.append([escape(row.label), String(row.count), String(row.totalQuantity)].joined(separator: ","))
        }
        lines.append("")
        lines.append("Transfer Orders")
        lines.append("Status,Count")
        for row in transferSummary {
            lines.append([escape(row.label), String(row.count)].joined(separator: ","))
        }
        lines.append("")
        lines.append("Low Stock Items")
        lines.append("SKU,Item,Warehouse,Quantity,Threshold,Unit Cost,Value At Risk")
        for item in lowStockItems {
            lines.append([
                escape(item.sku),
                escape(item.name),
                escape(warehouseNames[item.warehouseID] ?? "Unknown Warehouse"),
                String(item.currentQuantity),
                String(item.minimumThreshold),
                money(item.unitCost),
                money(Double(item.currentQuantity) * item.unitCost)
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func money(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
