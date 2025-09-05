import Foundation

// This file is now primarily responsible for orchestrating the API checks
// and passing the detailed, typed data up to the UI and analytics layers.

@MainActor
class UsageMonitor {
    private var monitoringTimer: Timer?
    private let openAIMonitor = OpenAIMonitor()
    private let realTimeEstimator = RealTimeUsageEstimator()

    // The closure now passes both detailed usage and real-time estimates
    var onUsageUpdate: ((DetailedTokenUsage, RealTimeUsageEstimator.RealTimeEstimates) -> Void)?
    var onPollingIntervalChanged: ((TimeInterval) -> Void)?

    private var currentPollingInterval: TimeInterval = 15 * 60  // Default 15 minutes
    private var consecutiveErrors: Int = 0
    private let maxBackoffInterval: TimeInterval = 30 * 60  // 30 minutes max backoff

    func startMonitoring() {
        stopMonitoring()

        // Start with initial check and default interval
        scheduleNextCheck(interval: currentPollingInterval)

        // Initial check on startup
        Task { @MainActor in
            await checkUsage()
        }
    }

    private func scheduleNextCheck(interval: TimeInterval) {
        stopMonitoring()

        currentPollingInterval = interval
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) {
            [weak self] _ in
            Task { @MainActor in
                await self?.checkUsage()
            }
        }

        print("📡 Next API check scheduled in \(Int(interval)) seconds")
        onPollingIntervalChanged?(interval)
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    func checkUsage() async {
        do {
            // Fetch the latest usage data
            let usage = try await openAIMonitor.getCurrentUsage()

            // Update real-time estimator with new data
            realTimeEstimator.ingest(usage, hourlyBucketStarts: usage.hourlyBucketStarts)

            // Get current estimates
            let estimates = realTimeEstimator.getEstimates()

            // Determine next polling interval based on activity
            let recommendedInterval = realTimeEstimator.getRecommendedPollingInterval()

            print(
                "📊 Usage update - Today: \(usage.today), Week: \(usage.thisWeek), Month: \(usage.thisMonth), EMA: \(String(format: "%.2f", estimates.emaRateTokensPerMinute)) tpm"
            )

            // Notify UI with both usage and estimates
            onUsageUpdate?(usage, estimates)

            // Reset error count on success
            consecutiveErrors = 0

            // Schedule next check with adaptive interval
            scheduleNextCheck(interval: recommendedInterval)

        } catch APIError.missingAPIKey {
            print("ℹ️ OpenAI: No API key configured.")
            handleAPIError()
        } catch {
            print("⚠️ OpenAI API error: \(error.localizedDescription)")
            handleAPIError()
        }
    }

    private func handleAPIError() {
        consecutiveErrors += 1

        // Exponential backoff with jitter
        let baseBackoff = min(
            currentPollingInterval * pow(2.0, Double(consecutiveErrors)), maxBackoffInterval)
        let jitter = Double.random(in: 0.9...1.1)
        let backoffInterval = baseBackoff * jitter

        print("⚠️ API error #\(consecutiveErrors), backing off to \(Int(backoffInterval)) seconds")

        // Get current estimates (which will show decayed EMA)
        let estimates = realTimeEstimator.getEstimates()
        let fallbackUsage = DetailedTokenUsage()  // Empty usage data

        // Still notify UI so it can show decay
        onUsageUpdate?(fallbackUsage, estimates)

        // Schedule next check with backoff
        scheduleNextCheck(interval: backoffInterval)
    }
}
