import Foundation
import SwiftUI
import Sentry

/// Central coordinator for managing core application state, logic, and third-party services.
@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - Core Components
    @Published var appStore: ManagedAppStore
    @Published var viewModel: ContentViewModel
    @Published var launchCoordinator: LaunchCoordinator
    // Keep AppLauncherService private if not needed externally
    private var appLauncherService: AppLauncherService
    
    init() {
        // --- Initialize Core Components (Order matters) ---
        let store = ManagedAppStore()
        self.appStore = store
        
        let vm = ContentViewModel(appStore: store)
        self.viewModel = vm
        
        let launcherService = AppLauncherService(errorHandler: vm)
        self.appLauncherService = launcherService
        
        // Create LaunchCoordinator, passing Store, ViewModel (as ErrorHandler), and Service
        let coordinator = LaunchCoordinator(appStore: store, errorHandler: vm, appLauncherService: launcherService)
        self.launchCoordinator = coordinator
        
        // --- Initialize Services ---
        // Sentry (only enable Crash)
        if let dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String {
            SentrySDK.start { options in
                options.dsn = dsn
                options.enableAutoPerformanceTracing = false
                options.enableSwizzling = false
                options.enableNetworkTracking = false
                options.enableFileIOTracing = false
                options.enableCoreDataTracing = false
            }
        }
        
        // --- Final Setup ---
        Logger.info("AppCoordinator initialized.")
        coordinator.startMonitoring()
    }
    
    // MARK: - Service Methods
    func checkForUpdates() {
    }
}
