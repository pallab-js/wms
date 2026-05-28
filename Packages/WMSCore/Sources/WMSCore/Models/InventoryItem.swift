import Foundation

public struct InventoryItem: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var sku: String
    public var name: String
    public var description: String
    public var category: String
    public var unitOfMeasure: String
    public var currentQuantity: Int
    public var minimumThreshold: Int
    public var unitCost: Double
    public var warehouseID: UUID
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        sku: String,
        name: String,
        description: String = "",
        category: String = "",
        unitOfMeasure: String = "units",
        currentQuantity: Int = 0,
        minimumThreshold: Int = 0,
        unitCost: Double = 0.0,
        warehouseID: UUID,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.sku = sku
        self.name = name
        self.description = description
        self.category = category
        self.unitOfMeasure = unitOfMeasure
        self.currentQuantity = currentQuantity
        self.minimumThreshold = minimumThreshold
        self.unitCost = unitCost
        self.warehouseID = warehouseID
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
