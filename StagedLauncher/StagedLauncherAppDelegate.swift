import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var launchCoordinator: LaunchCoordinator?
    private var appearanceObservation: NSKeyValueObservation? // Store the KVO token

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.info("AppDelegate: Application finished launching.")

        // Setup the menu bar using the new service name
        MenuBarService.shared.setupMenuBar()

        // Register for the termination notification
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationWillTerminate(_:)),
            name: NSWorkspace.willPowerOffNotification, object: nil
        )

        updateDockIconForAppearance()

        // Observe effectiveAppearance changes using KVO
        appearanceObservation = NSApplication.shared.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.updateDockIconForAppearance()
            }
        }
    }

    @objc
    func applicationWillTerminate(_ notification: Notification) {
        Logger.info("AppDelegate: Application will terminate.")
        // Clean up timers when the app quits
        launchCoordinator?.stopMonitoring()

        // Invalidate KVO observation
        appearanceObservation?.invalidate()
        appearanceObservation = nil
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(
            title: "Switch to Menu Bar Only",
            action: #selector(MenuBarService.toggleMenuBarPreference),
            keyEquivalent: ""
        )
        toggleItem.target = MenuBarService.shared
        menu.addItem(toggleItem)
        return menu
    }

    @objc func updateDockIconForAppearance() {
        let appearance = NSApp.effectiveAppearance
        let isDarkMode = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        Logger.info("Updating dock icon for appearance: \(isDarkMode ? "Dark Mode" : "Light Mode")")

        let iconName = isDarkMode ? "AppIconDark" : "AppIcon"

        if let icon = NSImage(named: iconName) {
            NSApp.applicationIconImage = icon
        } else {
            Logger.warning("Could not load dock icon named: \(iconName). Using default.")
            NSApp.applicationIconImage = NSImage(named: "AppIcon")
        }
    }
}
