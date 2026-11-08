import Foundation
import SwiftUI

/// Owns the app's long-lived objects and wires them together.
@MainActor
final class AppCoordinator: ObservableObject {
    let appStore: ManagedAppStore
    let viewModel: ContentViewModel
    private let launchCoordinator: LaunchCoordinator

    init() {
        let store = ManagedAppStore()
        let viewModel = ContentViewModel(appStore: store)
        let launcherService = AppLauncherService(errorHandler: viewModel)
        appStore = store
        self.viewModel = viewModel
        launchCoordinator = LaunchCoordinator(appStore: store, appLauncherService: launcherService)

        Logger.info("AppCoordinator initialized.")
        launchCoordinator.startMonitoring()
    }
}
