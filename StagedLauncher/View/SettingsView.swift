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
        // Use TabView for standard macOS settings structure
        TabView {
            // General Settings Tab
            Form { // Keep the Form for layout within the tab
                Toggle("Launch at Login", isOn: $loginItemService.launchAtLoginEnabled)
                    .onChange(of: loginItemService.launchAtLoginEnabled) { _, _ in
                        loginItemService.toggleLaunchAtLogin()
                    }
                    .help("When on, Staged Launcher will be added to your macOS Login Items and launch at each login.")
                    .toggleStyle(.checkbox)

                Divider()

                // Menu Bar Icon Toggle
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                    .onChange(of: showMenuBarIcon) { _, newValue in
                        self.defaults.set(newValue, forKey: Constants.showMenuBarIconKey)
                        MenuBarService.shared.updateMenuBarIconVisibility(shouldShow: newValue)
                    }
                    .help("When enabled, hides the Dock icon and places Staged Launcher in the menu bar; disable to restore the Dock icon.")
                    .toggleStyle(.checkbox)

                Divider() // Added divider

                Toggle("Show App Launch Notifications", isOn: $enableNotifications)
                    .onChange(of: enableNotifications) { _, newValue in
                        if newValue {
                            NotificationService.shared.requestAuthorizationIfNeeded()
                        } else {
                            Logger.info("Notifications disabled by user setting.")
                        }
                    }
                    .help("When on, you’ll get a notification in Notification Center after delayed app launched.")
                    .toggleStyle(.checkbox)

                Divider() // Added divider

                Toggle("Quit When All Apps Have Launched", isOn: $enabledQuitSelf)
                    .onChange(of: enabledQuitSelf) { _, newValue in
                        self.defaults.set(newValue, forKey: Constants.enabledQuitSelfKey)
                    }
                    .help("When enabled, Staged Launcher will automatically quit itself once all selected apps have finished launching.")
                    .toggleStyle(.checkbox)
            }
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .padding(20) // Add padding around the Form content inside the tab
        } // End TabView
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 300, minHeight: 120, idealHeight: 140, maxHeight: 160)
    }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserDefaults.standard.register(defaults: [Constants.showMenuBarIconKey: true])
        return SettingsView()
    }
}
