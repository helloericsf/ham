import Foundation
import Security

// The APIProvider enum is no longer needed as we are only supporting OpenAI.

final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()
    private let service = "com.ham.api-keys"
    private let account = "openai"  // Hardcoded for OpenAI

    private init() {}

    func setAPIKey(_ key: String) -> Bool {
        let data = key.data(using: .utf8)!

        // First, delete any existing key
        _ = deleteAPIKey()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
            let data = dataTypeRef as? Data,
            let key = String(data: data, encoding: .utf8)
        {
            return key
        }

        return nil
    }

    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}
