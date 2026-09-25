import Foundation
import WMSCore
import os

private let logger = Logger(subsystem: "com.warehouseos", category: "DataStore")

public final class WMSDataStore: Sendable {
    private let baseURL: URL
    private let lock = OSAllocatedUnfairLock()
    private let dataProtector: (any DataProtection)?

    public init(baseURL: URL? = nil, dataProtector: (any DataProtection)? = nil) {
        if let baseURL {
            self.baseURL = baseURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseURL = appSupport.appendingPathComponent("WarehouseOS", isDirectory: true)
        }
        self.dataProtector = dataProtector
        do {
            try FileManager.default.createDirectory(at: self.baseURL, withIntermediateDirectories: true)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: self.baseURL.path)
        } catch {
            logger.error("Failed to prepare storage directory: \(error, privacy: .public)")
        }
    }

    public func load<T: Codable>(_ type: T.Type, file: String) throws -> T {
        let url = try fileURL(for: file)
        let rawData = try lock.withLock {
            try loadRawUnsafe(url: url, file: file)
        }
        do {
            return try JSONDecoder().decode(type, from: rawData)
        } catch {
            throw WMSError.persistenceFailed("\(file) could not be decoded: \(error.localizedDescription)")
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
        let url = try fileURL(for: file)
        let data = try loadRawUnsafe(url: url, file: file)
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw WMSError.persistenceFailed("\(file) could not be decoded: \(error.localizedDescription)")
        }
    }

    /// Call ONLY inside `atomicWrite` closure or under `lock.withLock` — does not acquire lock.
    private func loadRawUnsafe(url: URL, file: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return Data("[]".utf8)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw WMSError.persistenceFailed("Unable to read \(file): \(error.localizedDescription)")
        }
        guard !data.isEmpty else {
            throw WMSError.persistenceFailed("\(file) is empty and cannot be read. The file may be truncated or corrupt.")
        }
        guard let protector = dataProtector else { return data }
        do {
            return try protector.decrypt(data)
        } catch let error as WMSError {
            throw error
        } catch {
            throw WMSError.persistenceFailed("Unable to decrypt \(file): \(error.localizedDescription)")
        }
    }

    /// Call ONLY inside `atomicWrite` closure — does not acquire lock.
    internal func saveUnsafe<T: Codable>(_ items: T, file: String) throws {
        let url = try fileURL(for: file)
        var data: Data
        do {
            data = try JSONEncoder().encode(items)
        } catch {
            throw WMSError.persistenceFailed("\(file) could not be encoded: \(error.localizedDescription)")
        }
        if let protector = dataProtector {
            do {
                data = try protector.encrypt(data)
            } catch let error as WMSError {
                throw error
            } catch {
                throw WMSError.persistenceFailed("Unable to encrypt \(file): \(error.localizedDescription)")
            }
        }
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw WMSError.persistenceFailed("Unable to write \(file): \(error.localizedDescription)")
        }
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func fileURL(for file: String) throws -> URL {
        guard !file.isEmpty,
              !file.contains("/"),
              !file.contains("\\"),
              !file.contains("..")
        else {
            throw WMSError.validationError("Invalid storage file name.")
        }
        let base = baseURL.standardizedFileURL
        let url = base.appendingPathComponent(file).standardizedFileURL
        guard url.path.hasPrefix(base.path + "/") else {
            throw WMSError.validationError("Invalid storage file name.")
        }
        return url
    }
}
