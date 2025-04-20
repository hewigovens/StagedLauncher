import SwiftUI

struct SettingsView: View {
    // Use AppStorage to bind the UI toggle state to UserDefaults
    // The source of truth for the actual menu bar state is now handled explicitly
    @AppStorage(Constants.showMenuBarIconKey) private var showMenuBarIcon: Bool = UserDefaults.standard.bool(forKey: Constants.showMenuBarIconKey)

    // Controller for managing login item status
    @StateObject private var loginItemService = LoginItemService.shared

    var body: some View {
        Form(content: {
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

            Divider()

            VStack(alignment: .leading) {
                Text("Launch at Login")
                    .font(.headline)
                Toggle("Launch at Login", isOn: $loginItemService.launchAtLoginEnabled)
                    .padding(.bottom, 4)
                    .onChange(of: loginItemService.launchAtLoginEnabled) { _, _ in
                        loginItemService.toggleLaunchAtLogin()
                    }
            }
            .padding(.vertical, 8)
        }) // End Form content
        .padding()
        .frame(width: 350, height: 180)
    }
}

// Preview Provider
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        UserDefaults.standard.register(defaults: [Constants.showMenuBarIconKey: true])
        return SettingsView()
    }
}
