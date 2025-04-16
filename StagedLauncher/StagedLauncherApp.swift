import SwiftUI

@main
struct StagedLauncherApp: App {
    // Inject the App Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var appStore = AppStore()
    @StateObject var viewModel: ContentViewModel 
    @StateObject var launchManager: LaunchManager

    init() {
        let store = AppStore()
        _appStore = StateObject(wrappedValue: store)

        // Create ViewModel before LaunchManager
        let vm = ContentViewModel(appStore: store)
        _viewModel = StateObject(wrappedValue: vm)

        // Pass store and the viewModel (as ErrorHandler) to LaunchManager
        let manager = LaunchManager(appStore: store, errorHandler: vm)
        _launchManager = StateObject(wrappedValue: manager)

        // Pass the created LaunchManager to the AppDelegate
        appDelegate.launchManager = manager

        // Start launch manager monitoring after setup
        manager.startMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            // Pass the existing viewModel to ContentView
            ContentView(appStore: appStore, viewModel: viewModel)
                .environmentObject(launchManager)
                .frame(minWidth: 500, minHeight: 300) // Adjust size as needed
        }
        Settings {
            SettingsView()
        }
    }
}
