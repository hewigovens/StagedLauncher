import SwiftUI

@main
struct StagedLauncherApp: App {
    @StateObject private var appStore = AppStore()
    @StateObject var launchManager: LaunchManager

    init() {
        let store = AppStore()
        _appStore = StateObject(wrappedValue: store)
        _launchManager = StateObject(wrappedValue: LaunchManager(appStore: store))
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
