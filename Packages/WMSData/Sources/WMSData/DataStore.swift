import Foundation
import WMSCore
import os

public final class WMSDataStore: Sendable {
    private let baseURL: URL
    private let lock = OSAllocatedUnfairLock()

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
        try lock.withLock {
            try loadUnsafe(type, file: file)
        }
    }

    public func save<T: Codable>(_ items: T, file: String) throws {
        try lock.withLock {
            try saveUnsafe(items, file: file)
        }
    }

    /// Executes operations inside a single lock acquisition.
    /// Use `loadUnsafe`/`saveUnsafe` inside the closure to avoid reentrant deadlock.
    public func atomicWrite<T>(_ operations: (WMSDataStore) throws -> T) throws -> T {
        try lock.withLock {
            try operations(self)
        }
    }

    /// Call ONLY inside `atomicWrite` closure — does not acquire lock.
    internal func loadUnsafe<T: Codable>(_ type: T.Type, file: String) throws -> T {
        let url = baseURL.appendingPathComponent(file)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return try JSONDecoder().decode(T.self, from: Data("[]".utf8))
        }
        let data = try Data(contentsOf: url)
        if data.isEmpty {
            return try JSONDecoder().decode(T.self, from: Data("[]".utf8))
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    /// Call ONLY inside `atomicWrite` closure — does not acquire lock.
    internal func saveUnsafe<T: Codable>(_ items: T, file: String) throws {
        let url = baseURL.appendingPathComponent(file)
        let data = try JSONEncoder().encode(items)
        try data.write(to: url, options: .atomic)
    }
}
