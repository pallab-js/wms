import Foundation
import WMSCore

public final class WMSDataStore: @unchecked Sendable {
    private let baseURL: URL
    private let lock = NSLock()

    public init(baseURL: URL? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseURL = appSupport.appendingPathComponent("WarehouseOS", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.baseURL, withIntermediateDirectories: true)
    }

    public func load<T: Codable>(_ type: T.Type, file: String) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        let url = baseURL.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return try JSONDecoder().decode(T.self, from: "[]".data(using: .utf8)!)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func save<T: Codable>(_ items: T, file: String) throws {
        lock.lock()
        defer { lock.unlock() }
        let url = baseURL.appendingPathComponent(file)
        let data = try JSONEncoder().encode(items)
        try data.write(to: url, options: .atomic)
    }

    public func atomicWrite(_ operations: () throws -> Void) throws {
        lock.lock()
        defer { lock.unlock() }
        try operations()
    }
}
