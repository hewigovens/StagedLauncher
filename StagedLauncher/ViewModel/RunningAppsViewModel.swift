import AppKit
import Combine

@MainActor
final class RunningAppsViewModel: ObservableObject {
    @Published private(set) var runningApps: [RunningApp] = []

    /// Lists regular (Dock) apps, excluding Apple apps and Staged Launcher itself.
    func fetchRunningApps() {
        var seen = Set<String>()
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> RunningApp? in
                guard let bundleId = app.bundleIdentifier,
                      !bundleId.hasPrefix("com.apple."),
                      bundleId != Constants.selfBundleId,
                      seen.insert(bundleId).inserted,
                      let name = app.localizedName,
                      let icon = app.icon,
                      let url = app.bundleURL
                else { return nil }
                return RunningApp(name: name, bundleIdentifier: bundleId, icon: icon, url: url)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
