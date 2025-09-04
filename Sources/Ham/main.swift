import Cocoa
import SwiftUI

let app = NSApplication.shared
let delegate = HamApp()
app.delegate = delegate

class HamApp: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var menuBarManager: MenuBarManager!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from dock - we're a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize menu bar manager
        menuBarManager = MenuBarManager()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}

app.run()
