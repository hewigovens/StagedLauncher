import AppKit

struct AppLauncherService {
    private var errorHandler: ErrorPresentable?
    private let notifier: NotificationService

    init(
        errorHandler: ErrorPresentable?,
        notifier: NotificationService = .shared
    ) {
        self.errorHandler = errorHandler
        self.notifier = notifier
    }

    @MainActor
    func launchApp(_ app: ManagedApp) {
        // Check if the app is already running
        let isRunning = NSWorkspace.shared.runningApplications.contains { runningApp in
            runningApp.bundleIdentifier == app.bundleIdentifier
        }

        guard !isRunning else {
            Logger.info("AppLauncherService: Skipping launch for \(app.name) because it is already running.")
            return
        }

        guard
            let bookmarkData = app.bookmarkData
        else {
            let errorMessage = "AppLauncherService: Error - No bookmark data found for \(app.name). Cannot launch."
            Logger.error(errorMessage)
            errorHandler?.showError(message: errorMessage)
            return
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard
                url.startAccessingSecurityScopedResource()
            else {
                let errorMessage = "AppLauncherService: Error - Could not resolve secure URL for \(app.name). Bookmark data might be stale or invalid."
                Logger.error(errorMessage)
                errorHandler?.showError(message: errorMessage)
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            Logger.info("AppLauncherService: Attempting to launch \(app.name) at URL: \(url.path)")
            let configuration = NSWorkspace.OpenConfiguration()

            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { runningApp, error in
                self.handleCompletion(app: app, runningApp: runningApp, error: error)
            }
        } catch {
            let errorMessage = "AppLauncherService: Error resolving bookmark data or launching \(app.name): \(error.localizedDescription)"
            Logger.error(errorMessage)
            errorHandler?.showError(message: errorMessage)
        }
    }

    private func handleCompletion(
        app: ManagedApp,
        runningApp: NSRunningApplication?,
        error: Error?
    ) {
        Task { @MainActor in
            if let error = error {
                let errorMessage = "AppLauncherService: Error launching \(app.name): \(error.localizedDescription)"
                Logger.error(errorMessage)
                self.errorHandler?.showError(message: errorMessage)
            } else {
                Logger.info("AppLauncherService: Successfully launched \(app.name). Process ID: \(runningApp?.processIdentifier ?? 0)")
                if UserDefaults.standard
                    .bool(forKey: Constants.enableNotificationsKey)
                {
                    self.notifier.scheduleLaunchNotification(for: app)
                }
            }
        }
    }
}
