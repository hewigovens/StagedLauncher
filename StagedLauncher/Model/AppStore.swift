import Combine
import Foundation
import SwiftUI

/// Manages the list of managed applications and persists them.
class AppStore: ObservableObject {
    @Published var managedApps: [ManagedApp] = []

    init() {
        loadApps()
    }

    // MARK: - Persistence

    func saveApps() {
        if let encoded = try? JSONEncoder().encode(managedApps) {
            UserDefaults.standard.set(encoded, forKey: Constants.managedAppsUserDefaultsKey)
            print("Apps saved to UserDefaults.")
        } else {
            print("Error: Failed to encode apps for saving.")
        }
    }

    func loadApps() {
        if let savedApps = UserDefaults.standard.data(forKey: Constants.managedAppsUserDefaultsKey) {
            if let decodedApps = try? JSONDecoder().decode([ManagedApp].self, from: savedApps) {
                managedApps = decodedApps
                print("Apps loaded from UserDefaults.")
                return
            }
            print("Error: Failed to decode saved apps.")
        }
        // Initialize with empty or default if nothing saved/error decoding
        managedApps = []
        print("No saved apps found or error decoding, initializing empty list.")
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
