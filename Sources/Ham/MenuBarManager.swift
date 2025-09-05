import Cocoa
import SwiftUI

@MainActor
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem
    private var hamsterAnimator: HamsterAnimator
    private var usageMonitor: UsageMonitor
    private let settingsManager = SettingsWindowManager()
    private var frameUpdateTimer: Timer?
    private let analyticsEngine = UsageAnalyticsEngine()

    // Menu item references for dynamic updates
    private var todayUsageItem: NSMenuItem?
    private var weekUsageItem: NSMenuItem?
    private var monthUsageItem: NSMenuItem?
    private var activitySubmenu: NSMenu?

    override init() {
        print("🐹 Creating MenuBarManager...")

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        print("🐹 Status item created")

        // Initialize components
        hamsterAnimator = HamsterAnimator()
        usageMonitor = UsageMonitor()

        super.init()

        setupStatusItem()
        startMonitoring()
        print("🐹 MenuBarManager setup complete")
    }

    private func setupStatusItem() {
        print("🐹 Setting up status item...")
        guard let button = statusItem.button else {
            print("❌ Failed to create status item button")
            return
        }

        button.title = "HAM"
        button.target = self
        button.action = #selector(statusItemClicked)
        print("🐹 Status item button configured with title: HAM")

        // Create menu
        let menu = createMenu()
        statusItem.menu = menu
        print("🐹 Menu created and assigned")
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Main usage statistics
        todayUsageItem = NSMenuItem(title: "🔥 Today: Loading...", action: nil, keyEquivalent: "")
        todayUsageItem?.isEnabled = false
        menu.addItem(todayUsageItem!)

        weekUsageItem = NSMenuItem(title: "📊 This Week: Loading...", action: nil, keyEquivalent: "")
        weekUsageItem?.isEnabled = false
        menu.addItem(weekUsageItem!)

        monthUsageItem = NSMenuItem(
            title: "📅 This Month: Loading...", action: nil, keyEquivalent: "")
        monthUsageItem?.isEnabled = false
        menu.addItem(monthUsageItem!)

        menu.addItem(NSMenuItem.separator())

        // Recent activity submenu
        let activityMenuItem = NSMenuItem(
            title: "▶ Recent Activity", action: nil, keyEquivalent: "")
        activitySubmenu = NSMenu()
        activityMenuItem.submenu = activitySubmenu
        menu.addItem(activityMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Detailed stats (placeholder for future implementation)
        let detailsItem = NSMenuItem(
            title: "📈 View Detailed Stats...", action: #selector(openDetailedStats),
            keyEquivalent: "")
        detailsItem.target = self
        detailsItem.isEnabled = false  // TODO: Enable when stats window is implemented
        menu.addItem(detailsItem)

        // Settings
        let settingsItem = NSMenuItem(
            title: "⚙️ Settings...", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Quit
        let quitItem = NSMenuItem(
            title: "❌ Quit Ham", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func startMonitoring() {
        // Start usage monitoring and animation updates
        usageMonitor.onUsageUpdate = { [weak self] usage, estimates in
            self?.analyticsEngine.recordUsage(usage)
            self?.updateHamsterSpeed(estimates: estimates)
            self?.updateMenu(usage: usage, estimates: estimates)
        }

        usageMonitor.startMonitoring()
        hamsterAnimator.startAnimation()

        // Start timer to update the menu bar icon with current animation frame
        frameUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
            [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMenuBarIcon()
            }
        }

        print("🐹 Monitoring and animation started")
    }

    private func updateHamsterSpeed(estimates: RealTimeUsageEstimator.RealTimeEstimates) {
        // Use EMA rate for smooth, responsive animation
        let tokensPerMinute = estimates.emaRateTokensPerMinute

        hamsterAnimator.updateForTokenUsage(tokensPerMinute)

        print(
            "🐹 Animation updated - EMA Rate: \(String(format: "%.2f", tokensPerMinute)) tokens/min"
        )
    }

    private func updateMenuBarIcon() {
        if let button = statusItem.button {
            button.image = hamsterAnimator.currentFrame
        }
    }

    private func updateMenu(
        usage: DetailedTokenUsage, estimates: RealTimeUsageEstimator.RealTimeEstimates
    ) {
        let analytics = analyticsEngine.getCurrentAnalytics(from: usage)

        // Update main usage items
        updateMainUsageItems(analytics: analytics)

        // Update recent activity with real-time estimates
        updateRecentActivity(analytics: analytics, estimates: estimates)
    }

    private func updateMainUsageItems(analytics: UsageAnalytics) {
        let todayTrend = analytics.trends.todayVsYesterday
        let todayTitle =
            "🔥 Today: \(formatNumber(analytics.timeBasedStats.today)) tokens \(todayTrend.emoji) (\(todayTrend.displayString))"
        todayUsageItem?.title = todayTitle

        let weekTrend = analytics.trends.thisWeekVsLast
        let weekTitle =
            "📊 This Week: \(formatNumber(analytics.timeBasedStats.thisWeek)) tokens \(weekTrend.emoji) (\(weekTrend.displayString))"
        weekUsageItem?.title = weekTitle

        let monthTrend = analytics.trends.thisMonthVsLast
        let monthTitle =
            "📅 This Month: \(formatNumber(analytics.timeBasedStats.thisMonth)) tokens \(monthTrend.emoji) (\(monthTrend.displayString))"
        monthUsageItem?.title = monthTitle
    }

    private func updateRecentActivity(
        analytics: UsageAnalytics, estimates: RealTimeUsageEstimator.RealTimeEstimates
    ) {
        guard let submenu = activitySubmenu else { return }
        submenu.removeAllItems()

        // Real-time estimates (clearly labeled as estimates)
        let last3MinItem = NSMenuItem(
            title: "~ Last 3 min: \(formatNumber(estimates.last3MinTokens)) tokens",
            action: nil,
            keyEquivalent: ""
        )
        last3MinItem.isEnabled = false
        submenu.addItem(last3MinItem)

        let last15MinItem = NSMenuItem(
            title: "~ Last 15 min: \(formatNumber(estimates.last15MinTokens)) tokens",
            action: nil,
            keyEquivalent: ""
        )
        last15MinItem.isEnabled = false
        submenu.addItem(last15MinItem)

        submenu.addItem(NSMenuItem.separator())

        // EMA rate
        let emaRateText = String(format: "%.1f", estimates.emaRateTokensPerMinute)
        let emaItem = NSMenuItem(
            title: "Current rate: \(emaRateText) tokens/min",
            action: nil,
            keyEquivalent: ""
        )
        emaItem.isEnabled = false
        submenu.addItem(emaItem)

        submenu.addItem(NSMenuItem.separator())

        let stats = analytics.timeBasedStats

        let lastHourItem = NSMenuItem(
            title: "Last hour: \(formatNumber(stats.lastHour)) tokens",
            action: nil,
            keyEquivalent: ""
        )
        lastHourItem.isEnabled = false
        submenu.addItem(lastHourItem)

        let peakItem = NSMenuItem(
            title: "Peak today (hourly): \(formatNumber(stats.peakHourlyRate)) tokens",
            action: nil,
            keyEquivalent: ""
        )
        peakItem.isEnabled = false
        submenu.addItem(peakItem)

        submenu.addItem(NSMenuItem.separator())

        let activityLevel = getActivityLevel(estimates.emaRateTokensPerMinute * 60)  // Convert to hourly for level calculation
        let activityItem = NSMenuItem(
            title: "\(activityLevel.emoji) Activity: \(activityLevel.description)",
            action: nil,
            keyEquivalent: ""
        )
        activityItem.isEnabled = false
        submenu.addItem(activityItem)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        } else {
            return "\(number)"
        }
    }

    private func getActivityLevel(_ averageRate: Double) -> (emoji: String, description: String) {
        switch averageRate {
        case 0...50:
            return ("😴", "Very Low")
        case 51...200:
            return ("🚶‍♂️", "Low")
        case 201...1000:
            return ("🏃‍♂️", "Moderate")
        case 1001...5000:
            return ("🏃‍♀️", "High")
        default:
            return ("🔥", "Very High")
        }
    }

    @objc private func statusItemClicked() {
        // Menu will be shown automatically
        print("🐹 Status item clicked")
    }

    @objc private func openSettings() {
        print("🐹 Opening settings...")
        settingsManager.showSettings()
    }

    @objc private func openDetailedStats() {
        print("🐹 Opening detailed stats...")
        // TODO: Implement detailed statistics window
    }

    @objc private func quitApp() {
        print("🐹 Quitting Ham...")
        NSApplication.shared.terminate(self)
    }
}
