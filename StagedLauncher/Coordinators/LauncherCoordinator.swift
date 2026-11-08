import AppKit
import Combine

/// Runs one staged launch session: each managed app present when monitoring starts
/// launches at most once, `delaySeconds` after the session start.
///
/// Edits made while launches are pending are applied to the pending schedule
/// (disable cancels, enable or a new delay reschedules relative to the session start,
/// launching immediately when that time has already passed). Apps that already
/// launched and apps added mid-session are left alone until the next session.
@MainActor
final class LaunchCoordinator {
    private let appStore: ManagedAppStore
    private let appLauncherService: AppLauncherService
    private var cancellables = Set<AnyCancellable>()
    private var launchTimers: [UUID: Timer] = [:]
    private var sessionStart = Date()
    private var sessionAppIDs: Set<UUID> = []
    private var launchedAppIDs: Set<UUID> = []
    private var didLaunchAnyApp = false

    init(appStore: ManagedAppStore, appLauncherService: AppLauncherService) {
        self.appStore = appStore
        self.appLauncherService = appLauncherService
    }

    // MARK: - Public Methods

    func startMonitoring() {
        Logger.info("LaunchCoordinator: Starting launch session.")
        sessionStart = Date()
        sessionAppIDs = Set(appStore.managedApps.map(\.id))
        launchedAppIDs.removeAll()
        didLaunchAnyApp = false
        observeStore()
        reconcile(with: appStore.managedApps)
    }

    // MARK: - Scheduling

    private func reconcile(with apps: [ManagedApp]) {
        let pending = apps.filter {
            $0.isEnabled && sessionAppIDs.contains($0.id) && !launchedAppIDs.contains($0.id)
        }
        let pendingIDs = Set(pending.map(\.id))
        for id in launchTimers.keys where !pendingIDs.contains(id) {
            invalidateTimer(for: id)
        }
        var launchedNow = false
        for app in pending where schedule(app) {
            launchedNow = true
        }
        // Only a launch may trigger quitting; unrelated edits after the session must not.
        if launchedNow {
            quitIfFinished()
        }
    }

    /// Schedules `app`, or launches it right away when its time has passed.
    /// - Returns: `true` if it launched immediately.
    private func schedule(_ app: ManagedApp) -> Bool {
        invalidateTimer(for: app.id)
        let fireDate = sessionStart.addingTimeInterval(TimeInterval(app.delaySeconds))
        guard fireDate > Date() else {
            launch(appID: app.id)
            return true
        }
        Logger.info("LaunchCoordinator: Scheduling \(app.name) at \(fireDate).")
        let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.launchTimers.removeValue(forKey: app.id)
                self.launch(appID: app.id)
                self.quitIfFinished()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        launchTimers[app.id] = timer
        return false
    }

    private func launch(appID: UUID) {
        launchedAppIDs.insert(appID)
        guard let app = appStore.managedApps.first(where: { $0.id == appID }), app.isEnabled else { return }
        if appLauncherService.launchApp(app) {
            didLaunchAnyApp = true
        }
    }

    /// Quits once every pending launch has fired, if enabled. Requires that this session
    /// actually launched something, so opening the app manually to edit settings
    /// (with everything already running) does not quit it.
    private func quitIfFinished() {
        guard launchTimers.isEmpty, didLaunchAnyApp,
              UserDefaults.standard.bool(forKey: Constants.enabledQuitSelfKey)
        else { return }
        Logger.info("LaunchCoordinator: All launches done. Quitting as configured.")
        // Give in-flight launch completions a moment before terminating.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            NSApplication.shared.terminate(nil)
        }
    }

    private func invalidateTimer(for id: UUID) {
        launchTimers.removeValue(forKey: id)?.invalidate()
    }

    private func observeStore() {
        cancellables.removeAll()
        appStore.$managedApps
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] apps in
                self?.reconcile(with: apps)
            }
            .store(in: &cancellables)
    }
}
