import Foundation

public struct Warehouse: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public var code: String
    public var address: String
    public var capacity: Int
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        code: String,
        address: String,
        capacity: Int,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.address = address
        self.capacity = capacity
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
