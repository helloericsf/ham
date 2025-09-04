import Foundation

protocol APIMonitor: AnyObject, Sendable {
    func getCurrentUsage() async throws -> Int
    func hasValidAPIKey() -> Bool
}

final class AnthropicMonitor: APIMonitor, @unchecked Sendable {
    private let apiKey: String?

    init() {
        self.apiKey = KeychainManager.shared.getAPIKey(for: .anthropic)
    }

    func hasValidAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    func getCurrentUsage() async throws -> Int {
        guard apiKey != nil else {
            throw APIError.missingAPIKey
        }

        // TODO: Implement actual Anthropic API call to get usage
        // For now, return mock data
        return Int.random(in: 0...1000)
    }
}

final class OpenAIMonitor: APIMonitor, @unchecked Sendable {
    private let apiKey: String?

    init() {
        self.apiKey = KeychainManager.shared.getAPIKey(for: .openai)
    }

    func hasValidAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    func getCurrentUsage() async throws -> Int {
        guard apiKey != nil else {
            throw APIError.missingAPIKey
        }

        // Make API call to OpenAI usage endpoint
        let url = URL(string: "https://api.openai.com/v1/usage")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else {
                throw APIError.invalidResponse
            }

            // Parse OpenAI usage response
            let usageData = try JSONDecoder().decode(OpenAIUsageResponse.self, from: data)
            return usageData.totalTokens
        } catch {
            // For now, return mock data if API call fails
            return Int.random(in: 0...1000)
        }
    }
}

final class GoogleAIMonitor: APIMonitor, @unchecked Sendable {
    private let apiKey: String?

    init() {
        self.apiKey = KeychainManager.shared.getAPIKey(for: .googleai)
    }

    func hasValidAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    func getCurrentUsage() async throws -> Int {
        guard apiKey != nil else {
            throw APIError.missingAPIKey
        }

        // TODO: Implement actual Google AI API call to get usage
        // For now, return mock data
        return Int.random(in: 0...1000)
    }
}

enum APIError: Error {
    case missingAPIKey
    case invalidResponse
    case networkError
}

struct OpenAIUsageResponse: Codable {
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case totalTokens = "total_tokens"
    }
}
