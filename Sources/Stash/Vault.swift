import Foundation
import CryptoKit
import Security
import StashCore

final class Vault: @unchecked Sendable {
    let directory: URL
    private let key: SymmetricKey
    init() throws {
        directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Stash", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.stash.clipboard.vault", kSecAttrAccount as String: "encryption-key"]
        var result: CFTypeRef?
        var read = query; read[kSecReturnData as String] = true
        let status = SecItemCopyMatching(read as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, data.count == 32 {
            key = SymmetricKey(data: data)
        } else if status == errSecItemNotFound {
            // Never replace a missing key when encrypted history already exists.
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            guard !files.contains(where: { $0.pathExtension == "stash" }) else { throw VaultError.missingKey }
            let generated = SymmetricKey(size: .bits256)
            var add = query
            add[kSecValueData as String] = generated.withUnsafeBytes { Data($0) }
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let added = SecItemAdd(add as CFDictionary, nil)
            guard added == errSecSuccess else { throw VaultError.keychain(added) }
            key = generated
        } else { throw VaultError.keychain(status) }
    }
    func load() throws -> (clips: [Clip], unreadable: Int) {
        var clips: [Clip] = []; var unreadable = 0
        for url in try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) where url.pathExtension == "stash" {
            do { clips.append(try VaultCodec.open(Data(contentsOf: url), key: key)) }
            catch { unreadable += 1 }
        }
        return (clips.sorted { $0.lastCopiedAt > $1.lastCopiedAt }, unreadable)
    }
    func save(_ clip: Clip) throws {
        let url = directory.appendingPathComponent(clip.id.uuidString).appendingPathExtension("stash")
        try VaultCodec.seal(clip, key: key).write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    func delete(_ id: UUID) throws {
        let url = directory.appendingPathComponent(id.uuidString).appendingPathExtension("stash")
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
}
enum VaultError: LocalizedError {
    case missingKey, keychain(OSStatus)
    var errorDescription: String? {
        switch self {
        case .missingKey: "The encryption key is missing. Existing history was preserved. Restore the original Keychain key to unlock it."
        case .keychain(let code): "Keychain access failed (\(code)). Capture is disabled until the vault can be unlocked."
        }
    }
}
