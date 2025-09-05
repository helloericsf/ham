# 🤖 OpenAI API Integration Implementation Plan

This document provides a detailed technical plan for implementing real OpenAI usage tracking in Ham, replacing the current mock implementation with actual API integration.

## 🎯 Objectives

1. **Replace mock OpenAI usage tracking** with real API integration
2. **Handle OpenAI's delayed usage reporting** (24-hour delay)
3. **Implement local usage tracking** for real-time monitoring
4. **Add comprehensive error handling** for API failures
5. **Support multiple OpenAI models** and pricing tiers

## 📊 OpenAI Usage API Landscape

### Available APIs

| API Endpoint | Purpose | Data Freshness | Access Level |
|-------------|---------|---------------|--------------|
| `/v1/usage` | Historical usage | ~24h delay | Organization admin |
| `/v1/dashboard/billing/usage` | Billing data | ~24h delay | Organization admin |
| `/v1/models` | Available models | Real-time | Standard API key |

### Challenges
- **No real-time usage API**: OpenAI doesn't provide immediate usage data
- **Admin access required**: Usage APIs need organization admin permissions
- **Rate limiting**: Billing APIs have strict rate limits
- **Data delay**: Usage appears ~24 hours after actual consumption

## 🏗️ Implementation Strategy

### Hybrid Approach: Real-time Tracking + Historical Validation

```swift
// Two-tier system:
// 1. Local real-time tracking during API calls
// 2. Historical validation from OpenAI billing API

class OpenAIUsageManager {
    private let realtimeTracker = OpenAIRealtimeTracker()
    private let historicalValidator = OpenAIHistoricalValidator()
    
    func getCurrentUsage() async throws -> OpenAIUsage {
        // Primary: Return real-time tracked data
        let realtimeUsage = realtimeTracker.getTodayUsage()
        
        // Secondary: Validate against historical data (if available)
        if let historicalUsage = try? await historicalValidator.getYesterdayUsage() {
            realtimeTracker.calibrateWithHistorical(historicalUsage)
        }
        
        return realtimeUsage
    }
}
```

## 💾 Technical Implementation

### 1. Real-time Usage Tracking

```swift
// Local tracking system for immediate usage recording
@MainActor
class OpenAIRealtimeTracker: ObservableObject {
    private let storageKey = "openai_realtime_usage"
    private var dailyUsage: [String: OpenAIModelUsage] = [:]
    
    struct OpenAIModelUsage: Codable {
        let date: Date
        let model: String
        var promptTokens: Int
        var completionTokens: Int
        var requestCount: Int
        var estimatedCost: Decimal
        
        var totalTokens: Int {
            promptTokens + completionTokens
        }
    }
    
    // Record usage from actual API calls
    func recordAPIUsage(
        model: String,
        promptTokens: Int,
        completionTokens: Int,
        timestamp: Date = Date()
    ) {
        let dateKey = dateKeyFormatter.string(from: timestamp)
        let modelKey = "\(dateKey)_\(model)"
        
        if var existing = dailyUsage[modelKey] {
            existing.promptTokens += promptTokens
            existing.completionTokens += completionTokens
            existing.requestCount += 1
            existing.estimatedCost += calculateCost(
                model: model, 
                promptTokens: promptTokens, 
                completionTokens: completionTokens
            )
            dailyUsage[modelKey] = existing
        } else {
            dailyUsage[modelKey] = OpenAIModelUsage(
                date: timestamp,
                model: model,
                promptTokens: promptTokens,
                completionTokens: completionTokens,
                requestCount: 1,
                estimatedCost: calculateCost(
                    model: model,
                    promptTokens: promptTokens,
                    completionTokens: completionTokens
                )
            )
        }
        
        persistUsage()
        print("🤖 OpenAI usage recorded: \(model) +\(promptTokens + completionTokens) tokens")
    }
    
    func getTodayUsage() -> OpenAIUsage {
        let today = dateKeyFormatter.string(from: Date())
        let todayUsages = dailyUsage.values.filter { usage in
            dateKeyFormatter.string(from: usage.date) == today
        }
        
        return OpenAIUsage(
            totalTokens: todayUsages.reduce(0) { $0 + $1.totalTokens },
            totalCost: todayUsages.reduce(0) { $0 + $1.estimatedCost },
            modelBreakdown: Dictionary(grouping: todayUsages, by: \.model)
                .mapValues { $0.reduce(OpenAIModelUsage.zero, +) }
        )
    }
    
    private func calculateCost(model: String, promptTokens: Int, completionTokens: Int) -> Decimal {
        guard let pricing = OpenAIPricing.getPricing(for: model) else {
            print("⚠️ Unknown pricing for model: \(model)")
            return 0
        }
        
        let promptCost = Decimal(promptTokens) * pricing.promptCost / 1000
        let completionCost = Decimal(completionTokens) * pricing.completionCost / 1000
        return promptCost + completionCost
    }
}
```

### 2. Historical Usage Validation

```swift
// Validates local tracking against OpenAI's billing data
class OpenAIHistoricalValidator {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func getHistoricalUsage(for date: Date) async throws -> OpenAIHistoricalUsage {
        let dateStr = ISO8601DateFormatter().string(from: date)
        
        // Try new billing API first
        if let usage = try? await fetchFromBillingAPI(date: dateStr) {
            return usage
        }
        
        // Fallback to legacy usage API
        return try await fetchFromUsageAPI(date: dateStr)
    }
    
    private func fetchFromBillingAPI(date: String) async throws -> OpenAIHistoricalUsage {
        let url = URL(string: "https://api.openai.com/v1/dashboard/billing/usage?start_date=\(date)&end_date=\(date)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let billingResponse = try JSONDecoder().decode(OpenAIBillingResponse.self, from: data)
            return billingResponse.toUsage()
            
        case 401:
            throw OpenAIError.invalidAPIKey
            
        case 403:
            throw OpenAIError.insufficientPermissions
            
        case 429:
            throw OpenAIError.rateLimited
            
        default:
            print("⚠️ OpenAI Billing API error: \(httpResponse.statusCode)")
            throw OpenAIError.apiError(httpResponse.statusCode)
        }
    }
    
    private func fetchFromUsageAPI(date: String) async throws -> OpenAIHistoricalUsage {
        let url = URL(string: "https://api.openai.com/v1/usage?date=\(date)")!
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError(httpResponse.statusCode)
        }
        
        let usageResponse = try JSONDecoder().decode(OpenAIUsageResponse.self, from: data)
        return usageResponse.toUsage()
    }
}
```

### 3. Data Models

```swift
// Core usage data structures
struct OpenAIUsage {
    let totalTokens: Int
    let totalCost: Decimal
    let modelBreakdown: [String: OpenAIModelUsage]
    let timestamp: Date
    let dataSource: UsageDataSource
    
    enum UsageDataSource {
        case realtime // Local tracking
        case historical // OpenAI API
        case hybrid // Combined/validated
    }
}

struct OpenAIBillingResponse: Codable {
    let object: String
    let dailyCosts: [DailyCost]
    let totalUsage: Decimal
    
    struct DailyCost: Codable {
        let timestamp: TimeInterval
        let lineItems: [LineItem]
    }
    
    struct LineItem: Codable {
        let name: String
        let cost: Decimal
        let usage: Usage?
    }
    
    struct Usage: Codable {
        let promptTokens: Int?
        let completionTokens: Int?
        let totalTokens: Int?
        
        enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    func toUsage() -> OpenAIHistoricalUsage {
        // Convert billing response to standardized usage format
        var totalTokens = 0
        var totalCost: Decimal = 0
        var modelBreakdown: [String: Int] = [:]
        
        for dailyCost in dailyCosts {
            for lineItem in dailyCost.lineItems {
                totalCost += lineItem.cost
                if let usage = lineItem.usage {
                    let tokens = usage.totalTokens ?? (usage.promptTokens ?? 0) + (usage.completionTokens ?? 0)
                    totalTokens += tokens
                    modelBreakdown[lineItem.name, default: 0] += tokens
                }
            }
        }
        
        return OpenAIHistoricalUsage(
            totalTokens: totalTokens,
            totalCost: totalCost,
            modelBreakdown: modelBreakdown
        )
    }
}

// OpenAI pricing data
struct OpenAIPricing {
    static let pricingData: [String: ModelPricing] = [
        "gpt-4": ModelPricing(
            promptCost: 0.03, // per 1K tokens
            completionCost: 0.06
        ),
        "gpt-4-turbo": ModelPricing(
            promptCost: 0.01,
            completionCost: 0.03
        ),
        "gpt-3.5-turbo": ModelPricing(
            promptCost: 0.0015,
            completionCost: 0.002
        ),
        "gpt-3.5-turbo-instruct": ModelPricing(
            promptCost: 0.0015,
            completionCost: 0.002
        )
    ]
    
    struct ModelPricing {
        let promptCost: Decimal // USD per 1K tokens
        let completionCost: Decimal
    }
    
    static func getPricing(for model: String) -> ModelPricing? {
        // Try exact match first
        if let pricing = pricingData[model] {
            return pricing
        }
        
        // Try prefix matching for model variants
        for (key, pricing) in pricingData {
            if model.hasPrefix(key) {
                return pricing
            }
        }
        
        return nil
    }
}
```

### 4. Enhanced OpenAIMonitor Integration

```swift
final class OpenAIMonitor: APIMonitor, @unchecked Sendable {
    private let apiKey: String?
    private let realtimeTracker = OpenAIRealtimeTracker()
    private let historicalValidator: OpenAIHistoricalValidator?
    private let lastValidationKey = "openai_last_validation"
    
    init() {
        self.apiKey = KeychainManager.shared.getAPIKey(for: .openai)
        self.historicalValidator = apiKey.map { OpenAIHistoricalValidator(apiKey: $0) }
    }
    
    func hasValidAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    func getCurrentUsage() async throws -> Int {
        guard apiKey != nil else {
            throw APIError.missingAPIKey
        }
        
        // Get real-time tracked usage
        let realtimeUsage = realtimeTracker.getTodayUsage()
        
        // Validate with historical data if it's been a while
        await validateWithHistoricalData()
        
        return realtimeUsage.totalTokens
    }
    
    private func validateWithHistoricalData() async {
        guard let validator = historicalValidator else { return }
        
        let lastValidation = UserDefaults.standard.object(forKey: lastValidationKey) as? Date ?? Date.distantPast
        let hoursSinceLastValidation = Date().timeIntervalSince(lastValidation) / 3600
        
        // Only validate once every 6 hours to respect rate limits
        guard hoursSinceLastValidation >= 6 else { return }
        
        do {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let historicalUsage = try await validator.getHistoricalUsage(for: yesterday)
            
            // Compare and calibrate local tracking
            realtimeTracker.calibrateWithHistorical(historicalUsage)
            
            UserDefaults.standard.set(Date(), forKey: lastValidationKey)
            print("🤖 OpenAI usage validated against historical data")
            
        } catch {
            print("⚠️ OpenAI historical validation failed: \(error)")
            // Continue with local tracking even if validation fails
        }
    }
    
    // Public method for applications to record their OpenAI API usage
    func recordAPIUsage(model: String, promptTokens: Int, completionTokens: Int) {
        realtimeTracker.recordAPIUsage(
            model: model,
            promptTokens: promptTokens,
            completionTokens: completionTokens
        )
    }
}
```

### 5. Error Handling & Resilience

```swift
enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case insufficientPermissions
    case rateLimited
    case apiError(Int)
    case networkError(Error)
    case dataCorruption
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key not configured"
        case .invalidAPIKey:
            return "OpenAI API key is invalid"
        case .insufficientPermissions:
            return "API key lacks organization admin permissions for usage data"
        case .rateLimited:
            return "OpenAI API rate limit exceeded"
        case .apiError(let code):
            return "OpenAI API error: HTTP \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .dataCorruption:
            return "Local usage data is corrupted"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey:
            return "Add your OpenAI API key in Settings"
        case .invalidAPIKey:
            return "Verify your API key in OpenAI dashboard"
        case .insufficientPermissions:
            return "Use an organization admin API key for usage tracking"
        case .rateLimited:
            return "Usage validation will retry later"
        case .apiError, .networkError:
            return "Check your internet connection and try again"
        case .dataCorruption:
            return "Local usage data will be reset"
        }
    }
}

// Retry logic for API calls
class OpenAIAPIClient {
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    
    func performRequest<T: Codable>(
        _ request: URLRequest,
        responseType: T.Type
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw OpenAIError.apiError(0)
                }
                
                if httpResponse.statusCode == 429 {
                    // Rate limited - wait with exponential backoff
                    let delay = baseDelay * pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw OpenAIError.apiError(httpResponse.statusCode)
                }
                
                return try JSONDecoder().decode(T.self, from: data)
                
            } catch {
                lastError = error
                if attempt == maxRetries - 1 { break }
                
                // Wait before retrying (except for rate limits which are handled above)
                if case OpenAIError.rateLimited = error {
                    break // Don't retry rate limits beyond the built-in retry above
                }
                
                let delay = baseDelay * pow(1.5, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? OpenAIError.apiError(0)
    }
}
```

## 📁 File Structure

### New Files to Create
```
Sources/Ham/OpenAI/
├── OpenAIUsageManager.swift      # Main coordination class
├── OpenAIRealtimeTracker.swift   # Local usage tracking
├── OpenAIHistoricalValidator.swift # API validation
├── OpenAIPricing.swift           # Model pricing data
├── OpenAIAPIClient.swift         # HTTP client with retry logic
└── OpenAIModels.swift            # Data models and responses
```

### Files to Modify
- `Sources/Ham/APIMonitor.swift`: Update OpenAIMonitor implementation
- `Sources/Ham/UsageMonitor.swift`: Integration with new system
- `Sources/Ham/SettingsWindow.swift`: Add OpenAI-specific settings

## 🧪 Testing Strategy

### Unit Tests
```swift
class OpenAIIntegrationTests: XCTestCase {
    func testRealtimeTracking() {
        let tracker = OpenAIRealtimeTracker()
        tracker.recordAPIUsage(model: "gpt-4", promptTokens: 100, completionTokens: 50)
        
        let usage = tracker.getTodayUsage()
        XCTAssertEqual(usage.totalTokens, 150)
    }
    
    func testHistoricalValidation() async {
        // Mock historical API response
        let validator = OpenAIHistoricalValidator(apiKey: "test-key")
        // Test with mock server
    }
    
    func testErrorHandling() async {
        // Test various error conditions
    }
}
```

### Integration Tests
- Test with real OpenAI API (using test keys)
- Verify pricing calculations accuracy
- Test rate limiting behavior
- Validate data persistence

## 📋 Implementation Timeline

### Week 1: Foundation
- [ ] Create data models and structures
- [ ] Implement OpenAIRealtimeTracker
- [ ] Add basic error handling
- [ ] Unit tests for core functionality

### Week 2: API Integration
- [ ] Implement OpenAIHistoricalValidator
- [ ] Add retry logic and resilience
- [ ] Test with real OpenAI APIs
- [ ] Handle edge cases and errors

### Week 3: Integration & Polish
- [ ] Update OpenAIMonitor class
- [ ] Integrate with existing Ham architecture
- [ ] Add user-facing settings
- [ ] Comprehensive testing

### Week 4: Validation & Documentation
- [ ] Real-world testing with actual usage
- [ ] Performance optimization
- [ ] Documentation updates
- [ ] User guide for setup

## 🎯 Success Metrics

- **Accuracy**: Local tracking within 5% of historical validation
- **Performance**: <100ms response time for getCurrentUsage()
- **Reliability**: 99%+ uptime for usage tracking
- **User Experience**: Clear error messages and recovery guidance

## 🔧 Configuration Options

### Settings UI Additions
```swift
// New settings for OpenAI integration
struct OpenAISettingsView: View {
    @State private var enableHistoricalValidation = true
    @State private var validationFrequency = 6 // hours
    @State private var enableCostTracking = true
    @State private var apiKeyStatus: APIKeyStatus = .unknown
    
    var body: some View {
        GroupBox("OpenAI Settings") {
            Toggle("Enable Historical Validation", isOn: $enableHistoricalValidation)
            
            if enableHistoricalValidation {
                HStack {
                    Text("Validation Frequency:")
                    Picker("", selection: $validationFrequency) {
                        Text("1 hour").tag(1)
                        Text("6 hours").tag(6)
                        Text("12 hours").tag(12)
                        Text("24 hours").tag(24)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            
            Toggle("Track Costs", isOn: $enableCostTracking)
            
            HStack {
                Text("API Key Status:")
                StatusIndicator(status: apiKeyStatus)
            }
        }
    }
}
```

This implementation plan provides a robust, production-ready solution for OpenAI usage tracking that handles the limitations of OpenAI's delayed reporting while providing real-time insights to Ham users.