import SwiftUI

struct SettingsView: View {
    // Controller for managing login item status
    @StateObject private var loginItemController = LoginItemController()

    var body: some View {
        // Use a Form for standard settings layout
        Form {
            Toggle("Launch StagedLauncher at login", isOn: $loginItemController.launchAtLoginEnabled)
                .onChange(of: loginItemController.launchAtLoginEnabled) { _ in
                    // Call the controller method when the toggle changes
                    loginItemController.toggleLaunchAtLogin()
                }
        }
        .padding()
        // Add a fixed frame, common for settings windows
        .frame(width: 350, height: 100)
    }
}

#Preview {
    SettingsView()
}
