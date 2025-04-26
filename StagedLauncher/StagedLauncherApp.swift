import SwiftUI
import Sparkle
import Sentry

@main
struct StagedLauncherApp: App {
    // Inject the App Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Centralized coordinator for the entire application
    @StateObject private var appCoordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            // Pass dependencies from AppCoordinator to ContentView
            ContentView(appStore: appCoordinator.appStore, viewModel: appCoordinator.viewModel)
                .environmentObject(appCoordinator.launchCoordinator)
                .frame(minWidth: 480, minHeight: 300)
        }
        Settings {
            // Pass dependencies from AppCoordinator to SettingsView
            SettingsView(updaterController: appCoordinator.updaterController)
                .environmentObject(appCoordinator.appStore)
                .environmentObject(appCoordinator.launchCoordinator)
                .navigationTitle("Preferences")
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    // Use the coordinator to check for updates
                    appCoordinator.checkForUpdates()
                }
            }
        }
    }
}
