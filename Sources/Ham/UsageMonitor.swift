import Foundation

struct TokenUsage {
    let anthropic: Int
    let openai: Int
    let google: Int
    let timeWindowMinutes: Double
    let timestamp: Date

    init(anthropic: Int = 0, openai: Int = 0, google: Int = 0, timeWindowMinutes: Double = 60.0) {
        self.anthropic = anthropic
        self.openai = openai
        self.google = google
        self.timeWindowMinutes = timeWindowMinutes
        self.timestamp = Date()
    }
}

@MainActor
class UsageMonitor {
    private var monitoringTimer: Timer?
    private var apiMonitors: [APIMonitor] = []

    var onUsageUpdate: ((TokenUsage) -> Void)?

    init() {
        setupAPIMonitors()
    }

    private func setupAPIMonitors() {
        // Initialize API monitors (will check for API keys)
        apiMonitors = [
            AnthropicMonitor(),
            OpenAIMonitor(),
            GoogleAIMonitor()
        ]
    }

    func startMonitoring() {
        stopMonitoring()

        // Update every 30 seconds
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkUsage()
            }
        }

        // Initial check
        Task { @MainActor in
            await checkUsage()
        }
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }

    private func checkUsage() async {
        var anthropicUsage = 0
        var openaiUsage = 0
        var googleUsage = 0

        // Check each API monitor
        for monitor in apiMonitors {
            do {
                let usage = try await monitor.getCurrentUsage()

                switch monitor {
                case is AnthropicMonitor:
                    anthropicUsage = usage
                case is OpenAIMonitor:
                    openaiUsage = usage
                case is GoogleAIMonitor:
                    googleUsage = usage
                default:
                    break
                }
            } catch {
                print("Error fetching usage from \(type(of: monitor)): \(error)")
            }
        }

        let usage = TokenUsage(
            anthropic: anthropicUsage,
            openai: openaiUsage,
            google: googleUsage,
            timeWindowMinutes: 60.0
        )

        onUsageUpdate?(usage)
    }
}
