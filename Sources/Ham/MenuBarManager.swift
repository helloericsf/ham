import Cocoa
import SwiftUI

@MainActor
class MenuBarManager: NSObject {
    private var statusItem: NSStatusItem
    private var hamsterAnimator: HamsterAnimator
    private var usageMonitor: UsageMonitor
    private let settingsManager = SettingsWindowManager()

    override init() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        // Initialize components
        hamsterAnimator = HamsterAnimator()
        usageMonitor = UsageMonitor()

        super.init()

        setupStatusItem()
        startMonitoring()
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else {
            print("Failed to create status item button")
            return
        }

        // Set initial hamster image
        button.image = hamsterAnimator.currentFrame
        button.target = self
        button.action = #selector(statusItemClicked)

        // Create menu
        let menu = createMenu()
        statusItem.menu = menu
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        // Usage summary
        let usageItem = NSMenuItem(title: "Token Usage: Loading...", action: nil, keyEquivalent: "")
        usageItem.isEnabled = false
        menu.addItem(usageItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(
            NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ""))

        // Quit
        menu.addItem(NSMenuItem(title: "Quit Ham", action: #selector(quitApp), keyEquivalent: "q"))

        return menu
    }

    private func startMonitoring() {
        // Start usage monitoring and animation updates
        usageMonitor.onUsageUpdate = { [weak self] usage in
            DispatchQueue.main.async {
                self?.updateHamsterSpeed(usage: usage)
                self?.updateMenu(usage: usage)
            }
        }

        usageMonitor.startMonitoring()
        hamsterAnimator.startAnimation()
    }

    private func updateHamsterSpeed(usage: TokenUsage) {
        let speed = calculateAnimationSpeed(from: usage)
        hamsterAnimator.setAnimationSpeed(speed)

        // Update the status item image
        if let button = statusItem.button {
            button.image = hamsterAnimator.currentFrame
        }
    }

    private func updateMenu(usage: TokenUsage) {
        guard let menu = statusItem.menu,
            let usageItem = menu.item(at: 0)
        else { return }

        let totalTokens = usage.anthropic + usage.openai + usage.google
        usageItem.title = "Tokens Today: \(totalTokens)"
    }

    private func calculateAnimationSpeed(from usage: TokenUsage) -> Double {
        let totalTokens = usage.anthropic + usage.openai + usage.google
        let tokensPerMinute = Double(totalTokens) / max(usage.timeWindowMinutes, 1.0)

        // Map tokens per minute to animation speed (0.1 to 3.0)
        let speed = min(max(tokensPerMinute / 1000.0, 0.1), 3.0)
        return speed
    }

    @objc private func statusItemClicked() {
        // Menu will be shown automatically
    }

    @objc private func openSettings() {
        settingsManager.showSettings()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }
}
