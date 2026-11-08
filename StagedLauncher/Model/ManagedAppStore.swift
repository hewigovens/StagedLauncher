import Combine
import Foundation

/// Manages the list of managed applications and persists them.
class ManagedAppStore: ObservableObject {
    @Published var managedApps: [ManagedApp] = []

    init() {
        loadApps()
        refreshStaleBookmarks()
    }

    // MARK: - Persistence

    func saveApps() {
        do {
            let data = try JSONEncoder().encode(managedApps)
            UserDefaults.standard.set(data, forKey: Constants.managedAppsUserDefaultsKey)
            Logger.info("Apps saved to UserDefaults.")
        } catch {
            Logger.error("Failed to encode apps for saving: \(error)")
        }
    }

    private func loadApps() {
        guard let data = UserDefaults.standard.data(forKey: Constants.managedAppsUserDefaultsKey) else {
            Logger.info("No saved apps found, initializing empty list.")
            return
        }
        do {
            managedApps = try JSONDecoder().decode([ManagedApp].self, from: data)
            Logger.info("Apps loaded from UserDefaults.")
        } catch {
            Logger.error("Failed to decode saved apps: \(error)")
            managedApps = []
        }
    }

    /// Re-creates stale bookmarks (common after an app updates itself) so they keep resolving.
    private func refreshStaleBookmarks() {
        var refreshed = false
        for index in managedApps.indices {
            guard let data = managedApps[index].bookmarkData else { continue }
            var isStale = false
            guard let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale),
                  isStale,
                  url.startAccessingSecurityScopedResource()
            else { continue }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                managedApps[index].bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                refreshed = true
                Logger.info("Refreshed stale bookmark for \(managedApps[index].name).")
            } catch {
                Logger.error("Failed to refresh bookmark for \(managedApps[index].name): \(error)")
            }
        }
        if refreshed {
            saveApps()
        }
    }

    // MARK: - App Management

    func addApp(name: String, bundleIdentifier: String, bookmark: Data?, category: String) {
        let newApp = ManagedApp.new(name: name, bundleIdentifier: bundleIdentifier, bookmark: bookmark, category: category)
        managedApps.append(newApp)
        saveApps()
    }

    func removeApp(id: UUID) {
        managedApps.removeAll { $0.id == id }
        saveApps()
    }

    func updateApp(_ app: ManagedApp) {
        guard let index = managedApps.firstIndex(where: { $0.id == app.id }),
              managedApps[index] != app
        else { return }
        managedApps[index] = app
        saveApps()
    }
}
