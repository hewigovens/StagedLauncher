import AppKit
import SwiftUI

class RunningAppsViewModel: ObservableObject {
    @Published var runningApps: [RunningApp] = []

    func fetchRunningApps() {
        var apps: [RunningApp] = []
        let running = NSWorkspace.shared.runningApplications

        for app in running {
            // Filter for regular applications that can be activated
            if app.activationPolicy == .regular,
               let name = app.localizedName,
               let bundleId = app.bundleIdentifier,
               let icon = app.icon,
               let url = app.bundleURL
            {
                let runningApp = RunningApp(
                    name: name,
                    bundleIdentifier: bundleId,
                    icon: icon,
                    url: url
                )
                apps.append(runningApp)
            }
        }

        // Sort alphabetically by name
        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // Update the published property on the main thread
        DispatchQueue.main.async {
            self.runningApps = apps
        }
    }
}
