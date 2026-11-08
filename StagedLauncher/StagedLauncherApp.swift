import SwiftUI

@main
struct StagedLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        Window("Staged Launcher", id: Constants.mainWindowID) {
            ContentView(viewModel: appCoordinator.viewModel)
                .frame(minWidth: 560, minHeight: 320)
        }
        .defaultSize(width: 720, height: 460)

        Settings {
            SettingsView()
        }
    }
}
