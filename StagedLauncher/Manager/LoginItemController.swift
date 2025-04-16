import ServiceManagement
import SwiftUI

class LoginItemController: ObservableObject {
    
    @Published var launchAtLoginEnabled: Bool = false

    private let service = SMAppService.mainApp

    init() {
        // Set initial state based on the service
        self.launchAtLoginEnabled = service.status == .enabled
    }

    func toggleLaunchAtLogin() {
        // Perform the operation asynchronously to avoid blocking the main thread
        Task {
            do {
                if service.status == .enabled {
                    try service.unregister()
                    print("Login item disabled successfully.")
                } else {
                    try service.register()
                    print("Login item enabled successfully.")
                }
                // Update state on the main thread after completion
                DispatchQueue.main.async {
                    self.launchAtLoginEnabled = self.service.status == .enabled
                }
            } catch {
                print("Failed to update login item: \(error.localizedDescription)")
                // Revert the state on the main thread after error
                DispatchQueue.main.async {
                    self.launchAtLoginEnabled = self.service.status == .enabled
                }
            }
        }
    }
}
