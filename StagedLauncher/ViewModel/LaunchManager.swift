import SwiftUI
import Combine
import AppKit

class LaunchManager: ObservableObject {
    private let appStore: AppStore
    private var cancellables = Set<AnyCancellable>()
    private var launchTimers: [UUID: Timer] = [:] // To manage individual app launch timers

    init(appStore: AppStore) {
        self.appStore = appStore
        // Potentially observe changes in appStore if needed in the future
        // setupBindings()
    }

    deinit {
        // Invalidate all timers when the manager is deallocated
        invalidateAllTimers()
    }

    // MARK: - Public Methods (Placeholders for now)

    func startMonitoring() {
        // Logic to start monitoring or prepare for launches (e.g., on app start)
        print("Launch Manager: Monitoring started.")
        // Example: Schedule launches based on current settings (implementation needed)
        scheduleLaunchesForAllEnabledApps()
    }

    func stopMonitoring() {
        // Logic to stop monitoring and clean up (e.g., on app quit)
        print("Launch Manager: Monitoring stopped.")
        invalidateAllTimers()
    }
    
    func scheduleLaunch(for app: ManagedApp) {
        guard app.isEnabled, app.delaySeconds > 0 else {
            print("Launch Manager: Skipping launch for disabled or zero-delay app: \(app.name)")
            // Ensure no existing timer for this app
            invalidateTimer(for: app.id)
            return
        }
        
        // Invalidate existing timer before scheduling a new one
        invalidateTimer(for: app.id)
        
        print("Launch Manager: Scheduling launch for \(app.name) in \(app.delaySeconds) seconds.")
        
        let timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(app.delaySeconds), repeats: false) { [weak self] _ in
            print("Launch Manager: Timer fired for \(app.name).")
            self?.launchApp(app)
            self?.launchTimers[app.id] = nil // Remove timer after firing
        }
        launchTimers[app.id] = timer
    }

    func scheduleLaunchesForAllEnabledApps() {
        invalidateAllTimers() // Clear existing timers first
        print("Launch Manager: Scheduling launches for all enabled apps.")
        for app in appStore.managedApps where app.isEnabled {
            scheduleLaunch(for: app)
        }
    }
    
    func appSettingsChanged(appId: UUID) {
        // Called when an app's delay or enabled status changes
        guard let app = appStore.managedApps.first(where: { $0.id == appId }) else { return }
        print("Launch Manager: Settings changed for \(app.name). Rescheduling.")
        scheduleLaunch(for: app) // Reschedule with new settings
    }

    // MARK: - Private Helpers
    
    private func launchApp(_ app: ManagedApp) {
        guard let url = app.resolvedURL else {
            print("Launch Manager: Error - Could not resolve URL for \(app.name).")
            return
        }
        
        print("Launch Manager: Attempting to launch \(app.name) at URL: \(url.path)")
        
        // Use NSWorkspace to launch the application
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { runningApp, error in
            if let error = error {
                print("Launch Manager: Error launching \(app.name): \(error.localizedDescription)")
                // TODO: Show user alert?
            } else {
                print("Launch Manager: Successfully launched \(app.name). Process ID: \(runningApp?.processIdentifier ?? 0)")
            }
        }
    }

    private func invalidateTimer(for id: UUID) {
        if let existingTimer = launchTimers[id] {
            print("Launch Manager: Invalidating existing timer for app ID \(id).")
            existingTimer.invalidate()
            launchTimers[id] = nil
        }
    }
    
    private func invalidateAllTimers() {
        print("Launch Manager: Invalidating all launch timers.")
        for timer in launchTimers.values {
            timer.invalidate()
        }
        launchTimers.removeAll()
    }

    // Example for observing changes (if needed later)
    /*
    private func setupBindings() {
        appStore.$managedApps
            .sink { [weak self] apps in
                // React to changes in the list of apps if necessary
                // self?.scheduleLaunchesForAllEnabledApps()
            }
            .store(in: &cancellables)
    }
    */
}
