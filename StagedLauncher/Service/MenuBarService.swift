import AppKit

class MenuBarService: NSObject {
    static let shared = MenuBarService()

    private var statusItem: NSStatusItem?
    private var toggleMenuItem: NSMenuItem?

    override private init() {}

    func setupMenuBar() {
        let initialSetting = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)
        updateMenuBarIconVisibility(shouldShow: initialSetting)
    }

    func updateMenuBarIconVisibility(shouldShow: Bool) {
        DispatchQueue.main.async {
            if shouldShow {
                NSApp.setActivationPolicy(.accessory)
                if self.statusItem == nil {
                    self.createMenuBarIcon()
                } else {
                    self.updateToggleMenuItemTitle(currentState: true)
                    self.statusItem?.isVisible = true
                }
            } else {
                NSApp.setActivationPolicy(.regular)
                if self.statusItem != nil {
                    self.removeMenuBarIcon()
                }
                if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    window.makeKeyAndOrderFront(nil)
                }
            }
        }
    }

    func setMenuBarVisibility(show: Bool) {
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

        if let icon = NSImage(systemSymbolName: "rectangle.stack", accessibilityDescription: nil) {
            icon.size = NSSize(width: 18, height: 18)
            icon.isTemplate = true
            button.image = icon
        } else {
            button.title = "🚀"
        }

        button.action = #selector(statusBarButtonClicked(sender:))
        button.target = self

        let menu = NSMenu()

        let aboutMenuItem = NSMenuItem(
            title: "About",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutMenuItem.target = self
        menu.addItem(aboutMenuItem)

        let settingsMenuItem = NSMenuItem(
            title: "Show Main Window",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)

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

    @objc func toggleMenuBarPreference() {
        let currentSetting = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)
        let newSetting = !currentSetting
        UserDefaults.standard.set(newSetting, forKey: Constants.showMenuBarIconKey)
        updateMenuBarIconVisibility(shouldShow: newSetting)
    }

    private func updateToggleMenuItemTitle(currentState showIcon: Bool) {
        if showIcon {
            toggleMenuItem?.title = "Show Dock Icon"
        } else {
            toggleMenuItem?.title = "Hide Dock Icon / Show Menu Bar Icon"
        }
    }

    @objc func statusBarButtonClicked(sender: NSStatusBarButton) {}

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    @objc func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let keyWindow = NSApp.keyWindow {
            keyWindow.makeKeyAndOrderFront(nil)
        } else if let mainWindow = NSApp.mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
        } else {
            Logger.info("MenuBarService: Activated app to show main window.")
        }
    }
}
