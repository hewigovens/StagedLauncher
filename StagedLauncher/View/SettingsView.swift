import SwiftUI

struct SettingsView: View {
    // Use AppStorage to bind the UI toggle state to UserDefaults
    // The source of truth for the actual menu bar state is now handled explicitly
    @AppStorage(Constants.showMenuBarIconKey) private var showMenuBarIcon: Bool = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)
    @AppStorage(Constants.enableNotificationsKey) private var enableNotifications: Bool = false

    // Controller for managing login item status
    @StateObject private var loginItemService = LoginItemService.shared

    var body: some View {
        // Use Form for standard macOS settings layout
        Form(content: {
            Toggle("Launch at Login", isOn: $loginItemService.launchAtLoginEnabled)
                .padding(.bottom, 4)
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
                    UserDefaults.standard.set(newValue, forKey: Constants.showMenuBarIconKey)
                    // Update the menu bar icon visibility using the service
                    MenuBarService.shared.updateMenuBarIconVisibility(shouldShow: newValue)
                }

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
        }) // End Form content
        .padding()
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
