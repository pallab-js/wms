import Foundation

public enum MovementType: String, Codable, Sendable {
    case stockIn
    case stockOut
    case adjustment
}

public struct StockMovement: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var movementType: MovementType
    public var quantity: Int
    public var note: String?
    public var referenceNumber: String?
    public var recordedAt: Date
    public var recordedByUserID: UUID?
    public var itemID: UUID
    public var warehouseID: UUID

    public init(
        id: UUID = UUID(),
        movementType: MovementType,
        quantity: Int,
        note: String? = nil,
        referenceNumber: String? = nil,
        recordedAt: Date = Date(),
        recordedByUserID: UUID? = nil,
        itemID: UUID,
        warehouseID: UUID
    ) {
        self.id = id
        self.movementType = movementType
        self.quantity = quantity
        self.note = note
        self.referenceNumber = referenceNumber
        self.recordedAt = recordedAt
        self.recordedByUserID = recordedByUserID
        self.itemID = itemID
        self.warehouseID = warehouseID
    }
}
