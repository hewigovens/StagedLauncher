import AppKit
import SwiftUI

class MenuBarService: NSObject {
    static let shared = MenuBarService()

    private var statusItem: NSStatusItem?
    private var toggleMenuItem: NSMenuItem?

    override private init() {}

    // Called once on app startup
    func setupMenuBar() {
        // Read the initial setting directly from UserDefaults
        let initialSetting = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)
        // Apply the initial state
        updateMenuBarIconVisibility(shouldShow: initialSetting)
    }

    // This function now *only* updates the UI based on the passed state
    func updateMenuBarIconVisibility(shouldShow: Bool) {
        DispatchQueue.main.async { // Ensure UI updates on main thread
            if shouldShow {
                NSApp.setActivationPolicy(.accessory)
                if self.statusItem == nil {
                    self.createMenuBarIcon()
                } else {
                    // If icon already exists, ensure it's visible and title is correct
                    self.updateToggleMenuItemTitle(currentState: true) // Pass current state
                    self.statusItem?.isVisible = true
                }
            } else {
                NSApp.setActivationPolicy(.regular)
                if self.statusItem != nil {
                    self.removeMenuBarIcon()
                } else {}
                // Activate app window only when switching to regular mode
                if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    // Public function called by SettingsView onChange
    func setMenuBarVisibility(show: Bool) {
        // Directly call the update function with the value from the toggle
        updateMenuBarIconVisibility(shouldShow: show)
    }

    private func createMenuBarIcon() {
        guard statusItem == nil else {
            return
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else {
            if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
            statusItem = nil
            return
        }

        // Use dedicated menu bar icon asset
        if let icon = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: nil) {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = true
            button.image = icon
        } else {
            button.title = "🚀"
        }

        button.action = #selector(statusBarButtonClicked(sender:))
        button.target = self

        // Build the menu
        let menu = NSMenu()

        let aboutMenuItem = NSMenuItem(
            title: "About",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)

        // Add Settings Menu Item
        let settingsMenuItem = NSMenuItem(
            title: "Show Main Window",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)

        // Separator before Toggle Item
        menu.addItem(NSMenuItem.separator())

        toggleMenuItem = NSMenuItem(
            title: "Show Dock Icon",
            action: #selector(toggleMenuBarPreference),
            keyEquivalent: ""
        )
        toggleMenuItem?.target = self
        updateToggleMenuItemTitle(currentState: true)
        menu.addItem(toggleMenuItem!)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        )

        statusItem?.menu = menu
        statusItem?.isVisible = true
    }

    private func removeMenuBarIcon() {
        guard let item = statusItem else {
            return
        }
        NSStatusBar.system.removeStatusItem(item)
        statusItem = nil
        toggleMenuItem = nil
    }

    // --- Actions ---

    // Action for the toggle menu item
    @objc func toggleMenuBarPreference() {
        // 1. Read the current setting from UserDefaults
        let currentSetting = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)

        // 2. Determine the new setting
        let newSetting = !currentSetting

        // 3. Save the new setting back to UserDefaults
        UserDefaults.standard.set(newSetting, forKey: Constants.showMenuBarIconKey)

        // 4. Update the UI based on the new setting
        updateMenuBarIconVisibility(shouldShow: newSetting)
    }

    // Helper to update the toggle item's title based on the current visibility state
    private func updateToggleMenuItemTitle(currentState showIcon: Bool) {
        if showIcon {
            toggleMenuItem?.title = "Show Dock Icon" // When icon is shown, option is to show dock
        } else {
            toggleMenuItem?.title = "Hide Dock Icon / Show Menu Bar Icon" // Clarify the action
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {}

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    /// Brings the main application window to the front.
    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let keyWindow = NSApp.keyWindow {
            keyWindow.makeKeyAndOrderFront(nil)
        } else if let mainWindow = NSApp.mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
        } else {
            // If there's truly no window, activating should trigger the App scene to create one.
            Logger.info("MenuBarService: Activated app to show main window.")
        }
    }
}
