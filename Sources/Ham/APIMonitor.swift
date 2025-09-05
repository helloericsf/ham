import Foundation

// A new struct to hold all the granular usage data from the API
struct DetailedTokenUsage {
    let today: Int
    let thisWeek: Int
    let thisMonth: Int
    let hourlyBreakdown: [Int]  // Last 24 hours, hour by hour
    let hourlyBucketStarts: [TimeInterval]  // Start times for each hourly bucket
    let timestamp: Date

    init(
        today: Int = 0, thisWeek: Int = 0, thisMonth: Int = 0, hourlyBreakdown: [Int] = [],
        hourlyBucketStarts: [TimeInterval] = []
    ) {
        self.today = today
        self.thisWeek = thisWeek
        self.thisMonth = thisMonth
        self.hourlyBreakdown = hourlyBreakdown
        self.hourlyBucketStarts = hourlyBucketStarts
        self.timestamp = Date()
    }
}

protocol APIMonitor: AnyObject, Sendable {
    // Updated to return the new detailed usage struct
    func getCurrentUsage() async throws -> DetailedTokenUsage
    func hasValidAPIKey() -> Bool
}

// MARK: - Cache Entry
struct CacheEntry {
    let data: [UsageBucket]
    let timestamp: Date
    let ttl: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > ttl
    }
}

// MARK: - OpenAI Usage API Models
struct OpenAIUsageResponse: Codable {
    let data: [UsageBucket]
    let object: String
    let hasMore: Bool?
    let nextPage: String?

    enum CodingKeys: String, CodingKey {
        case data
        case object
        case hasMore = "has_more"
        case nextPage = "next_page"
    }
}

struct UsageBucket: Codable {
    let object: String
    let startTime: Int
    let endTime: Int
    let results: [UsageResult]

    enum CodingKeys: String, CodingKey {
        case object
        case startTime = "start_time"
        case endTime = "end_time"
        case results
    }
}

struct UsageResult: Codable {
    let object: String
    let inputTokens: Int
    let outputTokens: Int
    let model: String?
    let numModelRequests: Int?

    enum CodingKeys: String, CodingKey {
        case object
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case model
        case numModelRequests = "num_model_requests"
    }

    var totalTokens: Int {
        return inputTokens + outputTokens
    }
}

final class OpenAIMonitor: APIMonitor, @unchecked Sendable {
    private let apiKey: String?
    private let usageKey = "openai_daily_tokens"  // Still useful for fallback
    private let lastResetKey = "openai_last_reset"
    private let dateFormatter: DateFormatter

    // Caching
    private var cache: [String: CacheEntry] = [:]
    private let cacheQueue = DispatchQueue(label: "openai.monitor.cache", attributes: .concurrent)

    init() {
        self.apiKey = KeychainManager.shared.getAPIKey()

        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd"

        // Clear cache on startup for debugging
        clearCache()

        resetDailyUsageIfNeeded()
    }

    func hasValidAPIKey() -> Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }

    private func resetDailyUsageIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReset =
            UserDefaults.standard.object(forKey: lastResetKey) as? Date ?? Date.distantPast

        if today > Calendar.current.startOfDay(for: lastReset) {
            UserDefaults.standard.set(0, forKey: usageKey)
            UserDefaults.standard.set(today, forKey: lastResetKey)
            print("🔥 OpenAI usage reset for new day")
        }
    }

    func getCurrentUsage() async throws -> DetailedTokenUsage {
        guard apiKey != nil else {
            throw APIError.missingAPIKey
        }

        resetDailyUsageIfNeeded()

        print("🔥 OpenAI fetching detailed usage from API...")

        do {
            let calendar = Calendar.current
            let now = Date()

            // Log current date and calendar info
            let dateFormatter = ISO8601DateFormatter()
            print("🕐 Current date: \(dateFormatter.string(from: now))")
            print("🕐 Calendar timezone: \(calendar.timeZone)")
            print("🕐 Calendar locale: \(String(describing: calendar.locale))")

            // Calculate local time boundaries with explicit date components
            let localStartOfToday = calendar.startOfDay(for: now)

            // Fix week calculation - use dateComponents instead of dateInterval
            let weekComponents = calendar.dateComponents(
                [.yearForWeekOfYear, .weekOfYear], from: now)
            let localStartOfWeek = calendar.date(from: weekComponents) ?? now

            // Fix month calculation - use dateComponents instead of dateInterval
            let monthComponents = calendar.dateComponents([.year, .month], from: now)
            let localStartOfMonth = calendar.date(from: monthComponents) ?? now

            // Log calculated boundaries
            print(
                "🕐 Today starts: \(dateFormatter.string(from: localStartOfToday)) (epoch: \(Int(localStartOfToday.timeIntervalSince1970)))"
            )
            print(
                "🕐 Week starts: \(dateFormatter.string(from: localStartOfWeek)) (epoch: \(Int(localStartOfWeek.timeIntervalSince1970)))"
            )
            print(
                "🕐 Month starts: \(dateFormatter.string(from: localStartOfMonth)) (epoch: \(Int(localStartOfMonth.timeIntervalSince1970)))"
            )

            // Fetch batched data
            async let hourlyData = fetchBatchedHourly(from: localStartOfWeek, to: now)
            async let dailyData = fetchBatchedDaily(
                from: localStartOfMonth.addingTimeInterval(-10 * 24 * 3600), to: now)

            let (hourlyBuckets, dailyBuckets) = try await (hourlyData, dailyData)

            // Calculate aggregates from batched data
            let today = calculatePeriodTotal(from: hourlyBuckets, startBoundary: localStartOfToday)
            let thisWeek = calculatePeriodTotal(
                from: hourlyBuckets, startBoundary: localStartOfWeek)

            // For month: sum full days from daily + today's partial from hourly
            let monthlyFromDaily = calculatePeriodTotal(
                from: dailyBuckets, startBoundary: localStartOfMonth, endBoundary: localStartOfToday
            )
            let thisMonth = monthlyFromDaily + today

            // Extract hourly breakdown and bucket starts
            let last24HourlyBuckets = hourlyBuckets.suffix(24)
            let hourlyBreakdown = last24HourlyBuckets.map { bucket in
                bucket.results.reduce(0) { $0 + $1.totalTokens }
            }
            let hourlyBucketStarts = last24HourlyBuckets.map { Double($0.startTime) }

            let detailedUsage = DetailedTokenUsage(
                today: today,
                thisWeek: thisWeek,
                thisMonth: thisMonth,
                hourlyBreakdown: Array(hourlyBreakdown),
                hourlyBucketStarts: Array(hourlyBucketStarts)
            )

            // Update local storage for fallback
            UserDefaults.standard.set(detailedUsage.today, forKey: usageKey)

            print(
                "🔥 OpenAI API returned: Today=\(detailedUsage.today), Week=\(detailedUsage.thisWeek), Month=\(detailedUsage.thisMonth)"
            )
            return detailedUsage

        } catch {
            print(
                "🔥 OpenAI usage API error: \(error). Falling back to local tracking for today's usage."
            )
            let storedUsage = UserDefaults.standard.integer(forKey: usageKey)
            // Return a default object with only the stored daily usage
            return DetailedTokenUsage(today: storedUsage)
        }
    }

    // MARK: - Batched Fetching Methods

    private func fetchBatchedHourly(from startDate: Date, to endDate: Date) async throws
        -> [UsageBucket]
    {
        let cacheKey =
            "hourly_\(Int(startDate.timeIntervalSince1970))_\(Int(endDate.timeIntervalSince1970))"

        // Check cache first
        if let cached = getCachedData(key: cacheKey, ttl: 150) {  // 2.5 minutes TTL
            print("🔄 Using cached hourly data for key: \(cacheKey)")
            return cached
        }

        print("🔄 Cache miss for hourly, fetching fresh data")
        let buckets = try await fetchUsage(from: startDate, to: endDate, bucketWidth: "1h")

        print("🔄 Fetched \(buckets.count) hourly buckets, caching result")

        // Cache the result
        setCachedData(key: cacheKey, data: buckets, ttl: 150)

        return buckets
    }

    private func fetchBatchedDaily(from startDate: Date, to endDate: Date) async throws
        -> [UsageBucket]
    {
        let cacheKey =
            "daily_\(Int(startDate.timeIntervalSince1970))_\(Int(endDate.timeIntervalSince1970))"

        // Check cache first - longer TTL for daily data
        if let cached = getCachedData(key: cacheKey, ttl: 1800) {  // 30 minutes TTL
            print("🔄 Using cached daily data for key: \(cacheKey)")
            return cached
        }

        print("🔄 Cache miss for daily, fetching fresh data")
        let buckets = try await fetchUsage(from: startDate, to: endDate, bucketWidth: "1d")

        print("🔄 Fetched \(buckets.count) daily buckets, caching result")

        // Cache the result
        setCachedData(key: cacheKey, data: buckets, ttl: 1800)

        return buckets
    }

    private func calculatePeriodTotal(
        from buckets: [UsageBucket], startBoundary: Date, endBoundary: Date? = nil
    ) -> Int {
        let startTime = Int(startBoundary.timeIntervalSince1970)
        let endTime = endBoundary.map { Int($0.timeIntervalSince1970) } ?? Int.max

        let filteredBuckets = buckets.filter { $0.startTime >= startTime && $0.startTime < endTime }

        if !filteredBuckets.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            print(
                "📊 Calculating period total: \(filteredBuckets.count) buckets between \(dateFormatter.string(from: startBoundary)) and \(endBoundary != nil ? dateFormatter.string(from: endBoundary!) : "now")"
            )
        }

        return filteredBuckets.reduce(0) { total, bucket in
            total + bucket.results.reduce(0) { $0 + $1.totalTokens }
        }
    }

    // MARK: - Caching Methods

    private func getCachedData(key: String, ttl: TimeInterval) -> [UsageBucket]? {
        return cacheQueue.sync {
            guard let entry = cache[key], !entry.isExpired else {
                if let entry = cache[key] {
                    print(
                        "🔄 Cache expired for key: \(key), TTL was \(entry.ttl)s, age: \(Date().timeIntervalSince(entry.timestamp))s"
                    )
                    cache.removeValue(forKey: key)
                }
                return nil
            }
            let age = Date().timeIntervalSince(entry.timestamp)
            print("🔄 Cache hit for key: \(key), age: \(Int(age))s, TTL: \(Int(entry.ttl))s")
            return entry.data
        }
    }

    private func setCachedData(key: String, data: [UsageBucket], ttl: TimeInterval) {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.cache[key] = CacheEntry(data: data, timestamp: Date(), ttl: ttl)
        }
    }

    // Clear all cached data (useful for debugging)
    func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            let count = self?.cache.count ?? 0
            self?.cache.removeAll()
            print("🧹 Cleared \(count) cached entries on startup")
        }
    }

    // MARK: - Core API Fetching

    private func fetchUsage(from startDate: Date, to endDate: Date, bucketWidth: String)
        async throws -> [UsageBucket]
    {
        guard let apiKey = apiKey else {
            throw APIError.missingAPIKey
        }

        let startTime = Int(startDate.timeIntervalSince1970)
        let endTime = Int(endDate.timeIntervalSince1970)

        var allBuckets: [UsageBucket] = []
        var nextPage: String? = nil
        var pageCount = 0
        let maxPages = 10  // Safety limit to prevent infinite loops

        // Loop through all pages
        repeat {
            pageCount += 1

            // Build URL with pagination parameter if available
            var urlString: String
            if let nextPage = nextPage {
                urlString =
                    "https://api.openai.com/v1/organization/usage/completions?start_time=\(startTime)&end_time=\(endTime)&bucket_width=\(bucketWidth)&page=\(nextPage)"
            } else {
                urlString =
                    "https://api.openai.com/v1/organization/usage/completions?start_time=\(startTime)&end_time=\(endTime)&bucket_width=\(bucketWidth)"
            }

            print("🔥 Calling OpenAI URL (page \(pageCount)): \(urlString)")

            guard let url = URL(string: urlString) else {
                throw APIError.invalidResponse
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "GET"

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            print("🌐 API Response: HTTP \(httpResponse.statusCode), \(data.count) bytes")

            guard httpResponse.statusCode == 200 else {
                let errorString = String(data: data, encoding: .utf8) ?? "No error details"
                print("🔥 OpenAI usage API error (\(httpResponse.statusCode)): \(errorString)")
                if httpResponse.statusCode == 401 { throw APIError.missingAPIKey }
                throw APIError.invalidResponse
            }

            // Log raw response for debugging (only for first page to avoid flooding)
            if pageCount == 1, let rawJSON = String(data: data, encoding: .utf8) {
                // Only log first 500 chars to avoid flooding
                let preview = rawJSON.prefix(500)
                print("🌐 Response preview: \(preview)\(rawJSON.count > 500 ? "..." : "")")
            }

            do {
                let decoder = JSONDecoder()
                let usageResponse = try decoder.decode(OpenAIUsageResponse.self, from: data)
                print("🌐 Page \(pageCount): Decoded \(usageResponse.data.count) usage buckets")

                // Accumulate buckets from this page
                allBuckets.append(contentsOf: usageResponse.data)

                // Check if there are more pages
                if let hasMore = usageResponse.hasMore, hasMore, let next = usageResponse.nextPage {
                    nextPage = next
                    print("🌐 More pages available, next page: \(next)")
                } else {
                    nextPage = nil
                    print("🌐 No more pages, total buckets collected: \(allBuckets.count)")
                }

            } catch {
                print("🔥 OpenAI usage API parsing error: \(error)")
                if let rawJSON = String(data: data, encoding: .utf8) {
                    print("🔥 Failed to parse JSON: \(rawJSON.prefix(1000))")
                }
                throw APIError.invalidResponse
            }

        } while nextPage != nil && pageCount < maxPages

        if pageCount >= maxPages {
            print("⚠️ Reached maximum page limit (\(maxPages)), may have incomplete data")
        }

        return allBuckets
    }
}

enum APIError: Error {
    case missingAPIKey
    case invalidResponse
    case networkError
}
