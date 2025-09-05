import Foundation

// MARK: - Data Models

struct UsageAnalytics {
    let totalTokens: Int  // Today's total tokens
    let timeBasedStats: TimeBasedStats
    let trends: UsageTrends
    let timestamp: Date

    struct TimeBasedStats {
        let lastHour: Int
        let today: Int
        let thisWeek: Int
        let thisMonth: Int
        let peakHourlyRate: Int
        let averageHourlyRate: Double
    }

    struct UsageTrends {
        let todayVsYesterday: TrendIndicator
        let thisWeekVsLast: TrendIndicator
        let thisMonthVsLast: TrendIndicator
    }

    struct TrendIndicator {
        let percentageChange: Double
        let isIncrease: Bool
        let isSignificant: Bool  // >5% change

        var displayString: String {
            let sign = isIncrease ? "+" : ""
            let formatted = String(format: "%.1f", abs(percentageChange))
            return "\(sign)\(formatted)%"
        }

        var emoji: String {
            if !isSignificant { return "━" }  // No significant change
            return isIncrease ? "📈" : "📉"
        }
    }
}

// MARK: - Analytics Engine

@MainActor
class UsageAnalyticsEngine: ObservableObject {
    private let storageKey = "ham_usage_history"
    // The history only needs to store daily totals for trend comparison.
    private var usageHistory: [String: UsageRecord] = [:]

    // MARK: - Data Structure

    private struct UsageRecord: Codable {
        let timestamp: Date
        let totalTokens: Int
    }

    // MARK: - Initialization

    init() {
        loadHistoricalData()
        startPeriodicCleanup()
    }

    // MARK: - Public Interface

    // This is the main entry point for new data from the API.
    // It records today's usage for future trend analysis.
    func recordUsage(_ usage: DetailedTokenUsage) {
        let dateKey = dateKey(for: usage.timestamp)
        let record = UsageRecord(timestamp: usage.timestamp, totalTokens: usage.today)
        usageHistory[dateKey] = record
        persistData()
        print("📊 Analytics engine recorded today's total: \(record.totalTokens) tokens")
    }

    // This method now takes the detailed usage data directly from the API monitor.
    func getCurrentAnalytics(from usage: DetailedTokenUsage) -> UsageAnalytics {
        let now = Date()

        // The time-based stats are now mostly derived from the accurate, API-provided data.
        let timeStats = calculateTimeBasedStats(from: usage)

        // Trends are calculated by comparing the new data with our stored history.
        let trends = calculateTrends(from: usage)

        return UsageAnalytics(
            totalTokens: usage.today,
            timeBasedStats: timeStats,
            trends: trends,
            timestamp: now
        )
    }

    // MARK: - Private Implementation

    private func calculateTimeBasedStats(from usage: DetailedTokenUsage)
        -> UsageAnalytics.TimeBasedStats
    {
        // Calculate hourly rates from the detailed hourly breakdown provided by the API.
        let (peakRate, avgRate, lastHour) = calculateHourlyRates(from: usage.hourlyBreakdown)

        return UsageAnalytics.TimeBasedStats(
            lastHour: lastHour,
            today: usage.today,
            thisWeek: usage.thisWeek,
            thisMonth: usage.thisMonth,
            peakHourlyRate: peakRate,
            averageHourlyRate: avgRate
        )
    }

    private func calculateTrends(from usage: DetailedTokenUsage) -> UsageAnalytics.UsageTrends {
        let todayUsage = usage.today
        let yesterdayUsage = getUsageForYesterday()
        let todayTrend = calculateTrend(current: todayUsage, previous: yesterdayUsage)

        let thisWeekUsage = usage.thisWeek
        let lastWeekUsage = getUsageForPeriod(.lastWeek)
        let weekTrend = calculateTrend(current: thisWeekUsage, previous: lastWeekUsage)

        let thisMonthUsage = usage.thisMonth
        let lastMonthUsage = getUsageForPeriod(.lastMonth)
        let monthTrend = calculateTrend(current: thisMonthUsage, previous: lastMonthUsage)

        return UsageAnalytics.UsageTrends(
            todayVsYesterday: todayTrend,
            thisWeekVsLast: weekTrend,
            thisMonthVsLast: monthTrend
        )
    }

    private func calculateTrend(current: Int, previous: Int) -> UsageAnalytics.TrendIndicator {
        guard previous > 0 else {
            return UsageAnalytics.TrendIndicator(
                percentageChange: current > 0 ? 100.0 : 0.0,
                isIncrease: current > 0,
                isSignificant: current > 0
            )
        }

        let change = Double(current - previous) / Double(previous) * 100
        let isSignificant = abs(change) >= 5.0

        return UsageAnalytics.TrendIndicator(
            percentageChange: change,
            isIncrease: change > 0,
            isSignificant: isSignificant
        )
    }

    // This now uses the accurate hourly data from the API.
    private func calculateHourlyRates(from hourlyBreakdown: [Int]) -> (
        peak: Int, average: Double, lastHour: Int
    ) {
        guard !hourlyBreakdown.isEmpty else {
            return (0, 0.0, 0)
        }

        let lastHour = hourlyBreakdown.last ?? 0
        let peakHour = hourlyBreakdown.max() ?? 0
        let totalTokens = hourlyBreakdown.reduce(0, +)
        let averagePerHour = Double(totalTokens) / Double(hourlyBreakdown.count)

        return (peak: peakHour, average: averagePerHour, lastHour: lastHour)
    }

    // MARK: - Data Retrieval Helpers for Trend Calculation

    private func getUsageForYesterday() -> Int {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayKey = dateKey(for: yesterday)
        return usageHistory[yesterdayKey]?.totalTokens ?? 0
    }

    private func getUsageForPeriod(_ period: TimePeriod) -> Int {
        let records = getRecordsForPeriod(period)
        return records.reduce(0) { $0 + $1.totalTokens }
    }

    private func getRecordsForPeriod(_ period: TimePeriod) -> [UsageRecord] {
        let calendar = Calendar.current
        let (startDate, endDate) = period.dateRange(relativeTo: Date(), calendar: calendar)

        var records: [UsageRecord] = []
        var currentDate = startDate

        while currentDate <= endDate {
            let dayKey = dateKey(for: currentDate)
            if let dayRecord = usageHistory[dayKey] {
                records.append(dayRecord)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? (endDate + 1)
        }

        return records
    }

    // MARK: - Data Persistence

    private func loadHistoricalData() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([String: UsageRecord].self, from: data)
        {
            usageHistory = decoded
            print("📊 Loaded usage history: \(usageHistory.keys.count) days")
        }
    }

    private func persistData() {
        if let encoded = try? JSONEncoder().encode(usageHistory) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func startPeriodicCleanup() {
        // Clean up old data weekly to prevent storage bloat
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupOldData()
            }
        }
    }

    private func cleanupOldData() {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        usageHistory = usageHistory.filter { key, _ in
            if let date = dateKeyFormatter.date(from: key) {
                return date >= cutoffDate
            }
            return false
        }

        persistData()
        print("📊 Cleaned up usage history older than 90 days")
    }

    // MARK: - Utilities

    private func dateKey(for date: Date) -> String {
        return dateKeyFormatter.string(from: date)
    }

    private var dateKeyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)  // Use UTC for keys
        return formatter
    }
}

// MARK: - Supporting Types

enum TimePeriod {
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth

    func dateRange(relativeTo date: Date, calendar: Calendar) -> (start: Date, end: Date) {
        switch self {
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            return (start: startOfWeek, end: date)

        case .lastWeek:
            let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: date) ?? date
            let startOfLastWeek =
                calendar.dateInterval(of: .weekOfYear, for: lastWeekDate)?.start ?? date
            let endOfLastWeek = calendar.date(byAdding: .day, value: 6, to: startOfLastWeek) ?? date
            return (start: startOfLastWeek, end: endOfLastWeek)

        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            return (start: startOfMonth, end: date)

        case .lastMonth:
            let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: date) ?? date
            let startOfLastMonth =
                calendar.dateInterval(of: .month, for: lastMonthDate)?.start ?? date
            let endOfLastMonth =
                calendar.date(
                    from: calendar.dateComponents([.year, .month], from: startOfLastMonth))?.adding(
                    months: 1, days: -1) ?? date
            return (start: startOfLastMonth, end: endOfLastMonth)
        }
    }
}

extension Date {
    func adding(months: Int, days: Int) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.month = months
        dateComponents.day = days
        return Calendar.current.date(byAdding: dateComponents, to: self)
    }
}
