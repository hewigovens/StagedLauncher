import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appearanceObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.info("AppDelegate: Application finished launching.")
        MenuBarService.shared.setupMenuBar()

        updateDockIconForAppearance()
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { _, _ in
            Task { @MainActor in
                NSApp.delegate.flatMap { $0 as? AppDelegate }?.updateDockIconForAppearance()
            }
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(
            title: String(localized: "Switch to Menu Bar Only"),
            action: #selector(MenuBarService.toggleMenuBarPreference),
            keyEquivalent: ""
        )
        toggleItem.target = MenuBarService.shared
        menu.addItem(toggleItem)
        return menu
    }

    private func updateDockIconForAppearance() {
        let isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let iconName = isDarkMode ? "AppIconDark" : "AppIcon"
        guard let icon = NSImage(named: iconName) else {
            Logger.warning("Could not load dock icon named \(iconName).")
            return
        }
        NSApp.applicationIconImage = icon
    }
}
