import Foundation

public protocol AlertRepository: Sendable {
    func fetchAll(unacknowledgedOnly: Bool) async throws -> [AlertRecord]
    func save(_ alert: AlertRecord) async throws
    func acknowledge(id: UUID) async throws
}
