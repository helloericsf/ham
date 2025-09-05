import Cocoa
import SwiftUI

class HamApp: NSObject, NSApplicationDelegate {
    var menuBarManager: MenuBarManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🐹 Ham starting...")

        // Hide from dock - we're a menu bar only app
        NSApp.setActivationPolicy(.accessory)
        print("🐹 Set activation policy to accessory")

        // Initialize menu bar manager
        menuBarManager = MenuBarManager()
        print("🐹 MenuBarManager initialized")
        print("🐹 Ham should now be visible in menu bar!")
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("🐹 Ham terminating...")
        print("🐹 Termination reason: \(notification)")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool)
        -> Bool
    {
        return false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// Set up the application
let app = NSApplication.shared
let delegate = HamApp()
app.delegate = delegate

// Keep the app running
app.run()
