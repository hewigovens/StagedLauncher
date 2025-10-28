import AppKit
import Combine

class RunningAppsViewModel: ObservableObject {
    @Published var runningApps: [RunningApp] = []

    func fetchRunningApps() {
        var apps: [RunningApp] = []
        let running = NSWorkspace.shared.runningApplications

        for app in running {
            guard let bundleId = app.bundleIdentifier else {
                continue
            }
            if bundleId.starts(with: "com.apple") || bundleId == Constants.selfBundleId {
                continue
            }

            if let name = app.localizedName,
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
