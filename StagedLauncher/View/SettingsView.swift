import SwiftUI

struct SettingsView: View {
    // Use AppStorage to bind the UI toggle state to UserDefaults
    // The source of truth for the actual menu bar state is now handled explicitly
    @AppStorage(Constants.showMenuBarIconKey) private var showMenuBarIcon: Bool = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey) // Initialize from UserDefaults

    // Controller for managing login item status
    @StateObject private var loginItemController = LoginItemController()

    var body: some View {
        Form(content: {
            // Menu Bar Icon Toggle
            Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                .padding(.vertical, 8)
                // Add onChange to notify MenuBarManager
                .onChange(of: showMenuBarIcon) { _, newValue in
                    MenuBarManager.shared.updateMenuBarIconVisibility(shouldShow: newValue)
                }

            Divider()

            VStack(alignment: .leading) {
                Text("Launch at Login")
                    .font(.headline)
                Toggle("Enabled", isOn: $loginItemController.launchAtLoginEnabled)
                    // Add onChange to trigger the controller action
                    .onChange(of: loginItemController.launchAtLoginEnabled) { _, _ in
                        // Call the function to actually enable/disable the login item
                        loginItemController.toggleLaunchAtLogin()
                    }
            }
            .padding(.vertical, 8)
        }) // End Form content
        .padding() // Standard padding for the whole form
        .frame(width: 350, height: 180) // Suggest an initial size
    }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserDefaults.standard.register(defaults: [Constants.showMenuBarIconKey: true])
        return SettingsView()
    }
}
