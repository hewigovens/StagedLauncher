import AppKit

/// Switches between Dock mode and menu-bar-only mode and owns the status item.
@MainActor
final class MenuBarService: NSObject {
    static let shared = MenuBarService()

    /// Opens (or focuses) the main window. Set by the main window's view, because
    /// SwiftUI's `openWindow` action is only available from the view hierarchy.
    var openMainWindow: (() -> Void)?

    private var statusItem: NSStatusItem?

    override private init() {}

    /// Applies the saved mode at launch without activating the app, so a login launch
    /// does not steal focus.
    func setupMenuBar() {
        applyMode(showMenuBarIcon: UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey))
    }

    func updateMenuBarIconVisibility(shouldShow: Bool) {
        applyMode(showMenuBarIcon: shouldShow)
        // Changing the activation policy deactivates the app and hides its windows.
        NSApp.activate()
    }

    private func applyMode(showMenuBarIcon shouldShow: Bool) {
        if shouldShow {
            NSApp.setActivationPolicy(.accessory)
            createMenuBarIconIfNeeded()
        } else {
            NSApp.setActivationPolicy(.regular)
            removeMenuBarIcon()
        }
    }

    private func createMenuBarIconIfNeeded() {
        guard statusItem == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: "Staged Launcher")
        image?.isTemplate = true
        item.button?.image = image

        let menu = NSMenu()
        menu.addItem(menuItem(String(localized: "Open Staged Launcher"), action: #selector(showMainWindow)))
        menu.addItem(menuItem(String(localized: "Settings…"), action: #selector(showSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(menuItem(String(localized: "Show Dock Icon"), action: #selector(toggleMenuBarPreference)))
        menu.addItem(menuItem(String(localized: "About Staged Launcher"), action: #selector(showAbout)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: String(localized: "Quit Staged Launcher"),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        item.menu = menu
        statusItem = item
    }

    private func menuItem(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    private func removeMenuBarIcon() {
        guard let statusItem else { return }
        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    // MARK: - Actions

    @objc func toggleMenuBarPreference() {
        let newSetting = !UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)
        UserDefaults.standard.set(newSetting, forKey: Constants.showMenuBarIconKey)
        updateMenuBarIconVisibility(shouldShow: newSetting)
    }

    @objc func showAbout() {
        NSApp.activate()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc func showMainWindow() {
        NSApp.activate()
        openMainWindow?()
    }

    @objc func showSettings() {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
