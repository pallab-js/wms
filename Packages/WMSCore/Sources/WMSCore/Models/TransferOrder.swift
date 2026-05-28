import Foundation

public enum TransferStatus: String, Codable, Sendable {
    case draft
    case submitted
    case approved
    case inTransit
    case completed
    case cancelled
}

public struct TransferOrder: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var transferCode: String
    public var status: TransferStatus
    public var sourceWarehouseID: UUID
    public var destinationWarehouseID: UUID
    public var requestedDate: Date
    public var completedDate: Date?
    public var notes: String
    public var lineItems: [TransferLineItem]

    public init(
        id: UUID = UUID(),
        transferCode: String,
        status: TransferStatus = .draft,
        sourceWarehouseID: UUID,
        destinationWarehouseID: UUID,
        requestedDate: Date = Date(),
        completedDate: Date? = nil,
        notes: String = "",
        lineItems: [TransferLineItem] = []
    ) {
        self.id = id
        self.transferCode = transferCode
        self.status = status
        self.sourceWarehouseID = sourceWarehouseID
        self.destinationWarehouseID = destinationWarehouseID
        self.requestedDate = requestedDate
        self.completedDate = completedDate
        self.notes = notes
        self.lineItems = lineItems
    }
}

public struct TransferLineItem: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var inventoryItemID: UUID
    public var requestedQuantity: Int
    public var transferredQuantity: Int

    public init(
        id: UUID = UUID(),
        inventoryItemID: UUID,
        requestedQuantity: Int,
        transferredQuantity: Int = 0
    ) {
        self.id = id
        self.inventoryItemID = inventoryItemID
        self.requestedQuantity = requestedQuantity
        self.transferredQuantity = transferredQuantity
    }
}
