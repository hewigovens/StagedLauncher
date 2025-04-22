import SwiftUI

struct SettingsView: View {
    // Use AppStorage to bind the UI toggle state to UserDefaults
    // The source of truth for the actual menu bar state is now handled explicitly
    @AppStorage(Constants.showMenuBarIconKey) private var showMenuBarIcon: Bool = UserDefaults.standard.bool(
        forKey: Constants.showMenuBarIconKey
    )
    @AppStorage(Constants.enableNotificationsKey) private var enableNotifications: Bool = false
    @AppStorage(Constants.enabledQuitSelfKey) private var enabledQuitSelf: Bool = UserDefaults.standard.bool(forKey: Constants.enabledQuitSelfKey)

    // Controller for managing login item status
    @StateObject private var loginItemService = LoginItemService.shared
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var body: some View {
        // Use Form for standard macOS settings layout
        Form(content: {
            Toggle("Launch at Login", isOn: $loginItemService.launchAtLoginEnabled)
                .onChange(of: loginItemService.launchAtLoginEnabled) { _, _ in
                    loginItemService.toggleLaunchAtLogin()
                }

            Divider()

            // Menu Bar Icon Toggle
            Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                .padding(.vertical, 8)
                // Add onChange to notify MenuBarService
                .onChange(of: showMenuBarIcon) { _, newValue in
                    // Save the new preference
                    self.defaults.set(newValue, forKey: Constants.showMenuBarIconKey)
                    // Update the menu bar icon visibility using the service
                    MenuBarService.shared.updateMenuBarIconVisibility(shouldShow: newValue)
                }
                .help("Show or hide the menu bar icon.")

            Toggle("Show App Launch Notifications", isOn: $enableNotifications)
                .onChange(of: enableNotifications) { _, newValue in
                    if newValue {
                        // Request permission when toggled on
                        NotificationService.shared.requestAuthorizationIfNeeded()
                    } else {
                        Logger.info("Notifications disabled by user setting.")
                    }
                }
                .help("Show a notification when a delayed app is launched.")
            Toggle("Quit Staged Launcher after all apps are launched", isOn: $enabledQuitSelf)
            .padding(.vertical, 8)
                .onChange(of: enabledQuitSelf) { _, newValue in
                    self.defaults.set(newValue, forKey: Constants.enabledQuitSelfKey)
                }
                .help("Quit the app when all apps are launched.")
        }) // End Form content
        .padding(.horizontal, 16)
        .frame(width: 350, height: 220)
    }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserDefaults.standard.register(defaults: [Constants.showMenuBarIconKey: true])
        return SettingsView()
    }
}
