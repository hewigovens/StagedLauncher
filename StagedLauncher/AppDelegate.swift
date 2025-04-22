import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var launchManager: LaunchManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.info("AppDelegate: Application finished launching.")

        // Setup the menu bar using the new service name
        MenuBarService.shared.setupMenuBar()

        // Register for the termination notification
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: NSWorkspace.willPowerOffNotification, object: nil)
    }

    @objc
    func applicationWillTerminate(_ notification: Notification) {
        Logger.info("AppDelegate: Application will terminate.")
        // Clean up timers when the app quits
        launchManager?.stopMonitoring()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // --- Dock Menu ---
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: "Switch to Menu Bar Only",
                                    action: #selector(MenuBarService.toggleMenuBarPreference),
                                    keyEquivalent: "")
        toggleItem.target = MenuBarService.shared
        menu.addItem(toggleItem)
        return menu
    }
}
