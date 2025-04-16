import SwiftUI

struct SettingsView: View {
    // Use AppStorage to bind the UI toggle state to UserDefaults
    // The source of truth for the actual menu bar state is now handled explicitly
    @AppStorage(Constants.showMenuBarIconKey) private var showMenuBarIcon: Bool = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey) // Initialize from UserDefaults

    // Controller for managing login item status
    @StateObject private var loginItemController = LoginItemController()


    var body: some View {
        // Using Form for standard settings layout
        Form {
            // Launch at Login Toggle
            Toggle("Launch at login", isOn: $loginItemController.launchAtLoginEnabled)
                .onChange(of: loginItemController.launchAtLoginEnabled) {
                    loginItemController.toggleLaunchAtLogin()
                }
                .toggleStyle(.switch)

            // Menu Bar Icon Toggle
            Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                .toggleStyle(.switch) // Use switch style for clarity
                .onChange(of: showMenuBarIcon) { _, newValue in
                    // AppStorage handles saving the value to UserDefaults automatically.
                    print("Settings Toggle changed to: \(newValue). Notifying MenuBarManager.")
                    // Explicitly tell the manager to update based on the new value
                    MenuBarManager.shared.setMenuBarVisibility(show: newValue)
                }
        }
        .padding()
        .frame(width: 300, height: 120) // Give the settings window a fixed size
    }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // Ensure a default value exists for preview if needed
         UserDefaults.standard.register(defaults: [Constants.showMenuBarIconKey : true])
        return SettingsView()
    }
}
