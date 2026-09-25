import Foundation
import CryptoKit
import os
import Security
import WMSCore

public final class KeychainDataProtector: @unchecked Sendable, DataProtection {
    private let lock = OSAllocatedUnfairLock()
    private var cachedKey: SymmetricKey?
    private let serviceName = "com.warehouseos.wms.encryption"
    private let accountName = "master-key"

    public init() {}

    public func encrypt(_ data: Data) throws -> Data {
        let key = try key()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw WMSError.persistenceFailed("Unable to encrypt data.")
        }
        return combined
    }

    public func decrypt(_ data: Data) throws -> Data {
        let key = try key()
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw WMSError.persistenceFailed(
                "Stored data could not be decrypted. It may be corrupt, or encrypted with a different key."
            )
        }
    }

    private func key() throws -> SymmetricKey {
        try lock.withLock {
            if let cached = cachedKey { return cached }
            let key = try loadOrCreateKey()
            cachedKey = key
            return key
        }
    }

    private func loadOrCreateKey() throws -> SymmetricKey {
        if let existing = try loadKeyFromKeychain() {
            return existing
        }
        let newKey = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(newKey)
        return newKey
    }

    /// Returns the stored key, or `nil` when no key exists yet.
    /// Any other status means the key exists but cannot be read (locked keychain,
    /// denied access) — that must never fall through to creating a replacement key,
    /// otherwise every existing file becomes permanently undecryptable.
    private func loadKeyFromKeychain() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess:
            guard let data = item as? Data, !data.isEmpty else {
                throw WMSError.persistenceFailed("The encryption key stored in the Keychain is unreadable.")
            }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw WMSError.persistenceFailed(
                "Unable to read the encryption key from the Keychain (status: \(status)). Unlock the keychain and try again."
            )
        }
    }

    private func storeKeyInKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw WMSError.persistenceFailed("Failed to store encryption key in Keychain (status: \(status)).")
        }
    }
}
