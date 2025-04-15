import Foundation
import SwiftUI
import AppKit // Import AppKit for NSOpenPanel

@MainActor
class ContentViewModel: ObservableObject {
    // Re-adding @Published to help ensure view updates when AppStore's published properties change.
    @Published var appStore: AppStore
    @Published var showingAlert = false
    @Published var alertMessage = ""
    
    // --- Filtering State --- 
    @Published var selectedCategory: String? = nil // Initially show all
    
    var categories: [String] {
        // Get unique categories, sort them, and add "All" at the beginning
        let uniqueCategories = Set(appStore.managedApps.map { $0.category })
        return ["All"] + uniqueCategories.sorted()
    }
    
    var filteredApps: [ManagedApp] {
        guard let category = selectedCategory, category != "All" else {
            return appStore.managedApps // Return all if nil or "All"
        }
        return appStore.managedApps.filter { $0.category == category }
    }
    // --- End Filtering State ---

    // --- Category Formatting ---
    func formatCategoryName(_ rawCategory: String) -> String {
        if rawCategory == "All" || rawCategory == "Other" {
            return rawCategory
        }
        
        let components = rawCategory.split(separator: ".")
        guard let lastComponent = components.last else {
            return rawCategory // Return raw if splitting fails
        }
        
        return lastComponent
            .replacingOccurrences(of: "-", with: " ")
            .capitalized // Capitalize the first letter of each word
    }
    // --- End Category Formatting ---

    init(appStore: AppStore) {
        self.appStore = appStore
    }

    // MARK: - App Management

    func removeApps(at offsets: IndexSet) {
        appStore.removeApp(at: offsets)
    }

    func removeApp(id: UUID) {
        appStore.removeApp(id: id)
    }
    
    func removeFilteredApps(at offsets: IndexSet) {
        // 1. Get the apps to remove from the filtered list based on the offsets
        let appsToRemove = offsets.map { filteredApps[$0] }
        
        // 2. Get their IDs
        let idsToRemove = appsToRemove.map { $0.id }
        
        // 3. Remove apps from the original store using their IDs
        idsToRemove.forEach { appStore.removeApp(id: $0) }
    }

    func presentOpenPanel() {
        let openPanel = NSOpenPanel()
        // Set the default directory to /Applications
        if let applicationsURL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first {
            openPanel.directoryURL = applicationsURL
        }

        openPanel.title = "Choose an Application"
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.applicationBundle] // Only allow .app files

        if openPanel.runModal() == .OK {
            guard let url = openPanel.url else {
                showError(message: "Could not get the selected application URL.")
                return
            }
            addApplication(from: url)
        }
    }

    public func addApplication(from url: URL) {
        guard let bundle = Bundle(url: url) else {
            showError(message: "Could not load bundle information for the selected application.")
            return
        }

        let appName = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? url.deletingPathExtension().lastPathComponent
        guard let bundleId = bundle.bundleIdentifier else {
            showError(message: "Could not determine the bundle identifier for the selected application.")
            return
        }

        // --- Read Category --- 
        let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String ?? "Other"
        let finalCategory = category.isEmpty ? "Other" : category
        // --- End Read Category ---

        // Create bookmark data
        var bookmarkData: Data?
        do {
            bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            showError(message: "Failed to create bookmark for application: \(error.localizedDescription)")
            // Decide if you want to proceed without a bookmark or stop
            // return
        }

        // Wrap the state update in DispatchQueue.main.async
        DispatchQueue.main.async {
            // Check if app already exists (optional, based on bundleId?)
            // if self.appStore.managedApps.contains(where: { $0.bundleIdentifier == bundleId }) { ... }
            
            // Pass category to addApp
            self.appStore.addApp(name: appName, bundleIdentifier: bundleId, bookmark: bookmarkData, category: finalCategory)
        }
    }

    // Helper to check if an app is already managed
    func isAppManaged(bundleIdentifier: String) -> Bool {
        return appStore.managedApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }

    // MARK: - Helpers

    // MARK: - Icon Retrieval

    func getAppIcon(for bookmarkData: Data?) -> NSImage {
        guard let data = bookmarkData else {
            // Return generic icon if no bookmark data
            return NSImage(systemSymbolName: "questionmark.app", accessibilityDescription: "Unknown App") ?? NSImage()
        }

        var isStale = false
        do {
            // Resolve the URL from bookmark data
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)

            // Handle stale bookmark data if necessary
            if isStale {
                // Optionally try to refresh the bookmark here
                print("Warning: Bookmark data is stale for \(url.lastPathComponent)")
            }

            // Important: Access the security-scoped resource
            guard url.startAccessingSecurityScopedResource() else {
                print("Error: Could not access security scoped resource for \(url.lastPathComponent)")
                return NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: "Access Denied") ?? NSImage()
            }

            // Use NSWorkspace to get the icon for the file URL
            let icon = NSWorkspace.shared.icon(forFile: url.path)

            // Stop accessing the resource
            url.stopAccessingSecurityScopedResource()

            return icon
        } catch {
            print("Error resolving bookmark data: \(error.localizedDescription)")
            return NSImage(systemSymbolName: "exclamationmark.arrow.triangle.2.circlepath", accessibilityDescription: "Resolution Failed") ?? NSImage()
        }
    }

    // MARK: - Error Handling

    func showError(message: String) {
        alertMessage = message
        showingAlert = true
        print("Error: \(message)") // Also log to console
    }
}
