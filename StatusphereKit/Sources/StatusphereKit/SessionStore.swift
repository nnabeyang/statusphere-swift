import AtprotoOAuth
import Foundation
import SecretBytes
import Security

/// Keeps the OAuth session in the Keychain.
///
/// The session holds the DPoP private key and the tokens, so it is sealed
/// with a random key before it leaves memory; the key is kept in the Keychain
/// next to it.
public struct SessionStore: Sendable {
  private static let service = "Statusphere"
  private static let sessionAccount = "session"
  private static let keyAccount = "session-key"
  private static let aad = Data("statusphere.session.v1".utf8)

  public init() {}

  public func load() throws -> AtprotoOAuthAgent.Archive? {
    guard let sealed = try read(account: Self.sessionAccount),
      let keyData = try read(account: Self.keyAccount)
    else {
      return nil
    }
    let key = try SecretBytes(bytes: keyData)
    return try SecretArchive.open(sealed, with: key, aad: Self.aad)
      .decode(AtprotoOAuthAgent.Archive.self)
  }

  public func save(_ archive: AtprotoOAuthAgent.Archive) throws {
    let key = try loadOrCreateKey()
    let sealed = try SecretArchive(encoding: archive).seal(with: key, aad: Self.aad)
    try write(sealed, account: Self.sessionAccount)
  }

  public func delete() {
    delete(account: Self.sessionAccount)
    delete(account: Self.keyAccount)
  }

  private func loadOrCreateKey() throws -> SecretBytes {
    if let keyData = try read(account: Self.keyAccount) {
      return try SecretBytes(bytes: keyData)
    }
    let key = SecretBytes(randomByteCount: 32)
    try write(key.withUnsafeBytes { Data($0) }, account: Self.keyAccount)
    return key
  }

  private func baseQuery(account: String) -> [CFString: Any] {
    [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: Self.service,
      kSecAttrAccount: account,
    ]
  }

  private func read(account: String) throws -> Data? {
    var query = baseQuery(account: account)
    query[kSecReturnData] = true
    query[kSecMatchLimit] = kSecMatchLimitOne

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    switch status {
    case errSecSuccess:
      return result as? Data
    case errSecItemNotFound:
      return nil
    default:
      throw KeychainError(status: status)
    }
  }

  private func write(_ data: Data, account: String) throws {
    delete(account: account)
    var query = baseQuery(account: account)
    query[kSecValueData] = data
    query[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError(status: status)
    }
  }

  private func delete(account: String) {
    SecItemDelete(baseQuery(account: account) as CFDictionary)
  }
}

public struct KeychainError: Error, CustomStringConvertible {
  public let status: OSStatus

  public var description: String {
    let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown error"
    return "Keychain error \(status): \(message)"
  }
}
