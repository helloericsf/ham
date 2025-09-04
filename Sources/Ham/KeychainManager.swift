import Foundation
import Security

enum APIProvider: String, CaseIterable {
    case anthropic = "anthropic"
    case openai = "openai"
    case googleai = "googleai"

    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic Claude"
        case .openai: return "OpenAI"
        case .googleai: return "Google AI"
        }
    }
}

final class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()
    private let service = "com.ham.api-keys"

    private init() {}

    func setAPIKey(_ key: String, for provider: APIProvider) -> Bool {
        let account = provider.rawValue
        let data = key.data(using: .utf8)!

        // First, delete any existing key
        _ = deleteAPIKey(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    func getAPIKey(for provider: APIProvider) -> String? {
        let account = provider.rawValue

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let key = String(data: data, encoding: .utf8) {
            return key
        }

        return nil
    }

    func deleteAPIKey(for provider: APIProvider) -> Bool {
        let account = provider.rawValue

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    func hasAPIKey(for provider: APIProvider) -> Bool {
        return getAPIKey(for: provider) != nil
    }

    func getAllConfiguredProviders() -> [APIProvider] {
        return APIProvider.allCases.filter { hasAPIKey(for: $0) }
    }
}
