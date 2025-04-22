import SwiftUI
import Sparkle

@main
struct StagedLauncherApp: App {
    // Inject the App Delegate
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Create the updater controller
    let updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)

    @StateObject private var appStore = AppStore()
    @StateObject var viewModel: ContentViewModel
    @StateObject var launchManager: LaunchManager

    init() {
        let store = AppStore()
        _appStore = StateObject(wrappedValue: store)

        // Create ViewModel before LaunchManager
        let vm = ContentViewModel(appStore: store)
        _viewModel = StateObject(wrappedValue: vm)

        // Create AppLauncherService, passing the ViewModel as the error handler
        let launcherService = AppLauncherService(errorHandler: vm)

        // Create LaunchManager, passing AppStore, ViewModel (as ErrorHandler), and AppLauncherService
        let manager = LaunchManager(appStore: store, errorHandler: vm, appLauncherService: launcherService)
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
                .frame(minWidth: 480, minHeight: 300)
        }
        Settings {
            SettingsView(updaterController: updaterController)
                .environmentObject(appStore)
                .environmentObject(launchManager)
                .navigationTitle("Preferences")
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController.checkForUpdates(nil)
                }
            }
        }
    }
}
