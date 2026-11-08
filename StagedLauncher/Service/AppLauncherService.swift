import AppKit

@MainActor
struct AppLauncherService {
    private weak var errorHandler: ErrorPresentable?
    private let notifier: NotificationService

    init(
        errorHandler: ErrorPresentable?,
        notifier: NotificationService = .shared
    ) {
        self.errorHandler = errorHandler
        self.notifier = notifier
    }

    /// Opens `app` unless it is already running.
    /// - Returns: `true` when a launch was requested, `false` when skipped or failed early.
    @discardableResult
    func launchApp(_ app: ManagedApp) -> Bool {
        let isRunning = NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == app.bundleIdentifier
        }
        guard !isRunning else {
            Logger.info("AppLauncherService: Skipping \(app.name); already running.")
            return false
        }

        let requested = app.withSecurityScopedURL { url in
            Logger.info("AppLauncherService: Launching \(app.name) at \(url.path).")
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { runningApp, error in
                let pid = runningApp?.processIdentifier
                let message = error?.localizedDescription
                Task { @MainActor in
                    handleCompletion(app: app, pid: pid, errorMessage: message)
                }
            }
            return true
        }
        guard requested == true else {
            errorHandler?.showError(message: String(localized: "Could not open \(app.name). Remove it and add it again to restore access."))
            return false
        }
        return true
    }

    private func handleCompletion(app: ManagedApp, pid: pid_t?, errorMessage: String?) {
        if let errorMessage {
            Logger.error("AppLauncherService: Failed to launch \(app.name): \(errorMessage)")
            errorHandler?.showError(message: String(localized: "Could not launch \(app.name): \(errorMessage)"))
            return
        }
        Logger.info("AppLauncherService: Launched \(app.name) (pid \(pid ?? 0)).")
        if UserDefaults.standard.bool(forKey: Constants.enableNotificationsKey) {
            notifier.scheduleLaunchNotification(for: app)
        }
    }
}
