import ServiceManagement

/// Registers Staged Launcher itself as a login item.
@MainActor
final class LoginItemService: ObservableObject {
    static let shared = LoginItemService()

    @Published private(set) var status: SMAppService.Status
    @Published private(set) var lastError: String?

    private let service = SMAppService.mainApp

    private init() {
        status = service.status
    }

    /// True when registered, including while waiting for approval in System Settings.
    var isEnabled: Bool {
        status == .enabled || status == .requiresApproval
    }

    func refresh() {
        status = service.status
    }

    func setEnabled(_ enabled: Bool) {
        lastError = nil
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            Logger.info("Login item \(enabled ? "registered" : "unregistered").")
        } catch {
            Logger.error("Failed to update login item: \(error.localizedDescription)")
            lastError = error.localizedDescription
        }
        refresh()
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
