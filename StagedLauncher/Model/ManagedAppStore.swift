import Combine
import Foundation

/// Manages the list of managed applications and persists them.
class ManagedAppStore: ObservableObject {
    @Published var managedApps: [ManagedApp] = []

    init() {
        loadApps()
    }

    // MARK: - Persistence

    func saveApps() {
        do {
            let data = try JSONEncoder().encode(managedApps)
            UserDefaults.standard.set(data, forKey: Constants.managedAppsUserDefaultsKey)
            Logger.info("Apps saved to UserDefaults.")
        } catch {
            Logger.error("Failed to encode apps for saving.")
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
            Logger.error("Failed to decode saved apps.")
            managedApps = [] // Initialize empty on decode failure
        }
    }

    // MARK: - App Management (Basic stubs for now)

    func addApp(name: String, bundleIdentifier: String, bookmark: Data?, category: String) {
        let newApp = ManagedApp.new(name: name, bundleIdentifier: bundleIdentifier, bookmark: bookmark, category: category)
        managedApps.append(newApp)
        saveApps()
    }

    func removeApp(at offsets: IndexSet) {
        managedApps.remove(atOffsets: offsets)
        saveApps()
    }

    func removeApp(id: UUID) {
        managedApps.removeAll { $0.id == id }
        saveApps()
    }

    func updateApp(_ app: ManagedApp) {
        guard let index = managedApps.firstIndex(where: { $0.id == app.id }) else { return }
        managedApps[index] = app
        saveApps()
    }
}
