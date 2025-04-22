import AppKit
import Combine
import SwiftUI

class LaunchManager: ObservableObject {
    private let appStore: AppStore
    private weak var errorHandler: ErrorPresentable?
    private let appLauncherService: AppLauncherService
    private var cancellables = Set<AnyCancellable>()
    private var launchTimers: [UUID: Timer] = [:]

    // Updated initializer to accept ErrorHandler and AppLauncherService
    init(appStore: AppStore, errorHandler: ErrorPresentable?, appLauncherService: AppLauncherService) {
        self.appStore = appStore
        self.errorHandler = errorHandler
        self.appLauncherService = appLauncherService
        // Observe changes to individual app settings (isEnabled, delaySeconds)
        // to automatically reschedule launches.
        setupBindings()
    }

    deinit {
        invalidateAllTimers()
    }

    // MARK: - Public Methods

    /// Call this when the app starts or when you want launching to begin.
    func startMonitoring() {
        Logger.info("Launch Manager: Starting monitoring and scheduling initial launches.")
        scheduleLaunchesForAllEnabledApps()
    }

    /// Call this when the app quits or when launching should stop.
    func stopMonitoring() {
        Logger.info("Launch Manager: Stopping monitoring and invalidating all timers.")
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        invalidateAllTimers()
    }

    /// Schedules a launch for a single app based on its current settings.
    func scheduleLaunch(for app: ManagedApp) {
        // Invalidate any existing timer for this app first
        invalidateTimer(for: app.id)

        // Only schedule if the app is enabled
        guard app.isEnabled else {
            Logger.info("Launch Manager: Skipping launch for disabled app: \(app.name)")
            return
        }

        // Launch immediately if delay is 0
        guard app.delaySeconds > 0 else {
            Logger.info("Launch Manager: Launching immediately (0 delay) for app: \(app.name)")
            Task {
                await appLauncherService.launchApp(app)
            }
            return
        }

        Logger.info("Launch Manager: Scheduling launch for \(app.name) in \(app.delaySeconds) seconds.")

        // Create and store the timer
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(app.delaySeconds), repeats: false) { [weak self] _ in
            Logger.info("Launch Manager: Timer fired for \(app.name).")
            Task {
                // Check if the app still exists and is enabled before launching
                if self?.appStore.managedApps.contains(where: { $0.id == app.id && $0.isEnabled }) ?? false {
                    Logger.info("Timer fired for \(app.name). Attempting launch.")
                    await self?.appLauncherService.launchApp(app)
                } else {
                    Logger.info("Launch cancelled for \(app.name) as it was removed or disabled.")
                }
                self?.launchTimers.removeValue(forKey: app.id)

                // Check if all apps are launched *after* this timer's app is processed
                self?.checkAndQuitIfAllTimersDone()
            }
        }
        launchTimers[app.id] = timer
    }

    /// Schedules launches for all apps currently marked as enabled in the AppStore.
    func scheduleLaunchesForAllEnabledApps() {
        Logger.info("Launch Manager: Scheduling launches for all enabled apps.")
        invalidateAllTimers()
        for app in appStore.managedApps where app.isEnabled {
            scheduleLaunch(for: app)
        }
    }

    /// Called automatically via bindings when an app's settings change.
    private func appSettingsChanged(appId: UUID) {
        guard let app = appStore.managedApps.first(where: { $0.id == appId }) else { return }
        Logger.info("Launch Manager: Settings changed detected for \(app.name). Rescheduling launch.")
        // Reschedule the specific app with its new settings
        scheduleLaunch(for: app)
    }

    // MARK: - Private Helpers

    /// Checks if all timers have completed and quits the app if the setting is enabled.
    private func checkAndQuitIfAllTimersDone() {
        if launchTimers.isEmpty {
            // Quit the app if enabled
            if UserDefaults.standard.bool(forKey: Constants.enabledQuitSelfKey) {
                Logger.info("Launch Manager: All timers finished. Quitting Staged Launcher as configured.")
                DispatchQueue.main.async { // Ensure UI updates on main thread
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    /// Invalidates and removes the timer for a specific app ID.
    private func invalidateTimer(for id: UUID) {
        if let existingTimer = launchTimers.removeValue(forKey: id) {
            Logger.info("Launch Manager: Invalidating existing timer for app ID \(id).")
            existingTimer.invalidate()
        }
    }

    /// Invalidates and removes all active launch timers.
    private func invalidateAllTimers() {
        Logger.info("Launch Manager: Invalidating all \(launchTimers.count) launch timers.")
        for timer in launchTimers.values {
            timer.invalidate()
        }
        launchTimers.removeAll()
    }

    /// Sets up Combine bindings to react to changes in app settings.
    private func setupBindings() {
        // Observe the array of managed apps itself (for additions/removals)
        appStore.$managedApps
            .dropFirst() // Ignore the initial value emitted when apps are first loaded
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Debounce to avoid rapid updates
            .sink { [weak self] updatedApps in
                guard let self = self else { return }
                self.performDifferentialUpdate(updatedApps: updatedApps)
            }
            .store(in: &cancellables)
    }

    /// Performs a differential update of launch timers based on the latest app list.
    private func performDifferentialUpdate(updatedApps: [ManagedApp]) {
        Logger.info("Launch Manager: App list change detected, performing differential update.")

        let currentTimerIDs = Set(launchTimers.keys)
        let newEnabledAppIDs = Set(updatedApps.filter { $0.isEnabled }.map { $0.id })

        // 1. IDs for timers that need to be invalidated (were running, but shouldn't be anymore)
        let idsToInvalidate = currentTimerIDs.subtracting(newEnabledAppIDs)
        for id in idsToInvalidate {
            invalidateTimer(for: id)
        }

        // 2. IDs for apps that need timers scheduled (should be running, but aren't yet)
        let idsToSchedule = newEnabledAppIDs.subtracting(currentTimerIDs)
        for id in idsToSchedule {
            if let appToSchedule = updatedApps.first(where: { $0.id == id }) {
                scheduleLaunch(for: appToSchedule)
            }
        }
    }
}
