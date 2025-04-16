import SwiftUI

@main
struct StagedLauncherApp: App {
    // Inject the App Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appStore = AppStore()
    @StateObject var launchManager: LaunchManager

    init() {
        let store = AppStore()
        _appStore = StateObject(wrappedValue: store)
        let manager = LaunchManager(appStore: store)
        _launchManager = StateObject(wrappedValue: manager)

        // Pass the created LaunchManager to the AppDelegate
        appDelegate.launchManager = manager
    }

    var body: some Scene {
        WindowGroup {
            ContentView(appStore: appStore)
                .environmentObject(launchManager)
        }
        Settings {
            SettingsView()
        }
    }
}
