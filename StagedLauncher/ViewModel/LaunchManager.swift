import AppKit
import Combine
import SwiftUI

class LaunchManager: ObservableObject {
    private let appStore: AppStore
    private weak var errorHandler: ErrorPresentable?
    private var cancellables = Set<AnyCancellable>()
    private var launchTimers: [UUID: Timer] = [:] // To manage individual app launch timers

    // Updated initializer to accept ErrorHandler
    init(appStore: AppStore, errorHandler: ErrorPresentable?) {
        self.appStore = appStore
        self.errorHandler = errorHandler
        // Observe changes to individual app settings (isEnabled, delaySeconds)
        // to automatically reschedule launches.
        setupBindings()
    }

    deinit {
        // Invalidate all timers when the manager is deallocated
        invalidateAllTimers()
    }

    // MARK: - Public Methods

    /// Call this when the app starts or when you want launching to begin.
    func startMonitoring() {
        Logger.info("Launch Manager: Starting monitoring and scheduling initial launches.")
        scheduleLaunchesForAllEnabledApps()
        setupAppStoreSubscription()
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
                await launchApp(app)
            }
            return
        }

        Logger.info("Launch Manager: Scheduling launch for \(app.name) in \(app.delaySeconds) seconds.")

        // Create and store the timer
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(app.delaySeconds), repeats: false) { [weak self] _ in
            Logger.info("Launch Manager: Timer fired for \(app.name).")
            Task {
                await self?.launchApp(app)
                self?.launchTimers.removeValue(forKey: app.id)
            }
        }
        launchTimers[app.id] = timer
    }

    /// Schedules launches for all apps currently marked as enabled in the AppStore.
    func scheduleLaunchesForAllEnabledApps() {
        Logger.info("Launch Manager: Scheduling launches for all enabled apps.")
        invalidateAllTimers() // Clear existing timers before rescheduling all
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

    @MainActor // Ensure this runs on the main thread due to showError call
    private func launchApp(_ app: ManagedApp) {
        // Check if the app is already running
        let isRunning = NSWorkspace.shared.runningApplications.contains { runningApp in
            runningApp.bundleIdentifier == app.bundleIdentifier
        }

        guard !isRunning else {
            Logger.info("Launch Manager: Skipping launch for \(app.name) because it is already running.")
            return
        }

        guard let bookmarkData = app.bookmarkData else {
            let errorMessage = "Launch Manager: Error - No bookmark data found for \(app.name). Cannot launch."
            Logger.error(errorMessage)
            errorHandler?.showError(message: errorMessage) // Use errorHandler
            return
        }

        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

            guard url.startAccessingSecurityScopedResource() else {
                let errorMessage = "Launch Manager: Error - Could not resolve secure URL for \(app.name). Bookmark data might be stale or invalid."
                Logger.error(errorMessage)
                errorHandler?.showError(message: errorMessage) // Use errorHandler
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            Logger.info("Launch Manager: Attempting to launch \(app.name) at URL: \(url.path)")
            let configuration = NSWorkspace.OpenConfiguration()

            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { runningApp, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let errorMessage = "Launch Manager: Error launching \(app.name): \(error.localizedDescription)"
                        Logger.error(errorMessage)
                        self.errorHandler?.showError(message: errorMessage) // Use errorHandler
                    } else {
                        Logger.info("Launch Manager: Successfully launched \(app.name). Process ID: \(runningApp?.processIdentifier ?? 0)")
                    }
                }
            }
        } catch {
            let errorMessage = "Launch Manager: Error resolving bookmark data or launching \(app.name): \(error.localizedDescription)"
            Logger.error(errorMessage)
            errorHandler?.showError(message: errorMessage) // Use errorHandler
        }
    }

    /// Invalidates and removes the timer for a specific app ID.
    private func invalidateTimer(for id: UUID) {
        if let existingTimer = launchTimers.removeValue(forKey: id) { // Removes and returns value
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
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Debounce to avoid rapid updates
            .sink { [weak self] _ in
                Logger.info("Launch Manager: App list changed, rescheduling all.")
                self?.scheduleLaunchesForAllEnabledApps()
            }
            .store(in: &cancellables)
    }

    private func setupAppStoreSubscription() {
        appStore.$managedApps
            .dropFirst() // Ignore the initial value
            .sink { [weak self] _ in
                Logger.info("Launch Manager: App list changed, rescheduling all.")
                self?.scheduleLaunchesForAllEnabledApps()
            }
            .store(in: &cancellables)
    }
}

