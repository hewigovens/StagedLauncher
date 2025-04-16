import ServiceManagement
import SwiftUI

class LoginItemController: ObservableObject {
    @Published var launchAtLoginEnabled: Bool = false

    private let service = SMAppService.mainApp

    init() {
        self.launchAtLoginEnabled = service.status == .enabled
    }

    func toggleLaunchAtLogin() {
        do {
            if service.status == .enabled {
                try service.unregister()
                print("Login item disabled successfully.")
            } else {
                try service.register()
                print("Login item enabled successfully.")
            }
            // Update the published property after the change
            DispatchQueue.main.async {
                self.launchAtLoginEnabled = self.service.status == .enabled
            }
        } catch {
            print("Failed to update login item: \(error.localizedDescription)")
            // Revert the state if there was an error
            DispatchQueue.main.async {
                self.launchAtLoginEnabled = self.service.status == .enabled
            }
        }
    }
}
