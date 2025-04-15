import SwiftUI
import Combine
import AppKit

class LaunchManager: ObservableObject {
    private let appStore: AppStore
    private var cancellables = Set<AnyCancellable>()
    private var launchTimers: [UUID: Timer] = [:] // To manage individual app launch timers

    init(appStore: AppStore) {
        self.appStore = appStore
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
        print("Launch Manager: Starting monitoring and scheduling initial launches.")
        scheduleLaunchesForAllEnabledApps()
    }

    /// Call this when the app quits or when launching should stop.
    func stopMonitoring() {
        print("Launch Manager: Stopping monitoring and invalidating all timers.")
        invalidateAllTimers()
    }
    
    /// Schedules a launch for a single app based on its current settings.
    func scheduleLaunch(for app: ManagedApp) {
        // Invalidate any existing timer for this app first
        invalidateTimer(for: app.id)
        
        // Only schedule if the app is enabled
        guard app.isEnabled else {
            print("Launch Manager: Skipping launch for disabled app: \(app.name)")
            return
        }
        
        // Launch immediately if delay is 0
        guard app.delaySeconds > 0 else {
            print("Launch Manager: Launching immediately (0 delay) for app: \(app.name)")
            launchApp(app)
            return
        }
        
        print("Launch Manager: Scheduling launch for \(app.name) in \(app.delaySeconds) seconds.")
        
        // Create and store the timer
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(app.delaySeconds), repeats: false) { [weak self] _ in
            print("Launch Manager: Timer fired for \(app.name).")
            self?.launchApp(app)
            // Remove timer after firing (important!)
            self?.launchTimers.removeValue(forKey: app.id)
        }
        launchTimers[app.id] = timer
    }

    /// Schedules launches for all apps currently marked as enabled in the AppStore.
    func scheduleLaunchesForAllEnabledApps() {
        invalidateAllTimers() // Clear existing timers before rescheduling all
        print("Launch Manager: Scheduling launches for all enabled apps.")
        for app in appStore.managedApps where app.isEnabled {
            scheduleLaunch(for: app)
        }
    }
    
    /// Called automatically via bindings when an app's settings change.
    private func appSettingsChanged(appId: UUID) {
        guard let app = appStore.managedApps.first(where: { $0.id == appId }) else { return }
        print("Launch Manager: Settings changed detected for \(app.name). Rescheduling launch.")
        // Reschedule the specific app with its new settings
        scheduleLaunch(for: app)
    }

    // MARK: - Private Helpers
    
    private func launchApp(_ app: ManagedApp) {
        // Check if the app is already running
        let isRunning = NSWorkspace.shared.runningApplications.contains { runningApp in
            runningApp.bundleIdentifier == app.bundleIdentifier
        }
        
        guard !isRunning else {
            print("Launch Manager: Skipping launch for \(app.name) because it is already running.")
            return
        }
        
        guard let url = app.resolvedURL else {
            print("Launch Manager: Error - Could not resolve secure URL for \(app.name). Bookmark data might be stale or invalid.")
            // TODO: Consider notifying the user or marking the app as problematic
            return
        }
        
        print("Launch Manager: Attempting to launch \(app.name) at URL: \(url.path)")
        
        let configuration = NSWorkspace.OpenConfiguration()
        // Set activates to false to launch in the background
        configuration.activates = false
        
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { runningApp, error in
            // Stop accessing the security-scoped resource as soon as possible
            url.stopAccessingSecurityScopedResource()
            
            DispatchQueue.main.async { // Ensure UI updates (if any) are on main thread
                if let error = error {
                    print("Launch Manager: Error launching \(app.name): \(error.localizedDescription)")
                    // TODO: Show user alert?
                } else {
                    print("Launch Manager: Successfully launched \(app.name). Process ID: \(runningApp?.processIdentifier ?? 0)")
                }
            }
        }
    }

    /// Invalidates and removes the timer for a specific app ID.
    private func invalidateTimer(for id: UUID) {
        if let existingTimer = launchTimers.removeValue(forKey: id) { // Removes and returns value
            print("Launch Manager: Invalidating existing timer for app ID \(id).")
            existingTimer.invalidate()
        }
    }
    
    /// Invalidates and removes all active launch timers.
    private func invalidateAllTimers() {
        print("Launch Manager: Invalidating all \(launchTimers.count) launch timers.")
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
                print("Launch Manager: App list changed, rescheduling all.")
                self?.scheduleLaunchesForAllEnabledApps()
            }
            .store(in: &cancellables)

        // Observe changes *within* each app (isEnabled, delaySeconds)
        // This requires observing the publisher for each app individually if ManagedApp is a struct.
        // A more robust way (if ManagedApp was a class) would be observing each app's properties.
        // Given ManagedApp is a struct, observing the whole array is simpler for now,
        // although potentially less efficient if only one app changes.
        // The debounce above helps mitigate frequent rescheduling.
        
        // Alternative (more complex with structs): If performance becomes an issue,
        // you'd need to manage individual subscriptions to each app's changes,
        // possibly by having AppStore vend publishers for individual app updates.
    }
}
