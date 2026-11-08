import AppKit
import Combine
import LSAppCategory
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject, ErrorPresentable {
    let appStore: ManagedAppStore
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var selectedCategory: String? = Constants.categoryAllApps
    @Published private(set) var loginItemPaths: Set<String> = []

    private var iconCache: [UUID: NSImage] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(appStore: ManagedAppStore) {
        self.appStore = appStore
        // Derived state (categories, filtered apps) depends on the store, so forward its changes.
        appStore.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        appStore.$managedApps
            .sink { [weak self] apps in self?.storeDidChange(apps) }
            .store(in: &cancellables)
        refreshLoginItems()
    }

    // MARK: - Categories

    var categories: [String] {
        let uniqueCategories = Set(appStore.managedApps.map(\.category))
        return [Constants.categoryAllApps] + uniqueCategories.sorted {
            formatCategoryName($0).localizedStandardCompare(formatCategoryName($1)) == .orderedAscending
        }
    }

    var filteredApps: [ManagedApp] {
        guard let category = selectedCategory, category != Constants.categoryAllApps else {
            return appStore.managedApps
        }
        return appStore.managedApps.filter { $0.category == category }
    }

    func appCount(in category: String) -> Int {
        category == Constants.categoryAllApps
            ? appStore.managedApps.count
            : appStore.managedApps.filter { $0.category == category }.count
    }

    func formatCategoryName(_ rawCategory: String) -> String {
        if rawCategory == Constants.categoryAllApps || rawCategory == Constants.categoryOther {
            return rawCategory
        }
        guard let lastComponent = rawCategory.split(separator: ".").last else {
            return rawCategory
        }
        return lastComponent
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    func symbolName(forCategory category: String) -> String {
        switch category {
        case Constants.categoryAllApps: "square.stack"
        case Constants.categoryOther: "questionmark.folder"
        default: AppCategory(string: category).sfSymbol
        }
    }

    // MARK: - App Management

    func binding(for app: ManagedApp) -> Binding<ManagedApp> {
        Binding(
            get: { [appStore] in appStore.managedApps.first { $0.id == app.id } ?? app },
            set: { [appStore] in appStore.updateApp($0) }
        )
    }

    func removeApp(id: UUID) {
        appStore.removeApp(id: id)
    }

    func revealInFinder(_ app: ManagedApp) {
        let revealed = app.withSecurityScopedURL { url in
            NSWorkspace.shared.activateFileViewerSelecting([url])
            return true
        }
        if revealed == nil {
            showError(message: String(localized: "Could not locate \(app.name)."))
        }
    }

    func presentOpenPanel() {
        let openPanel = NSOpenPanel()
        if let applicationsURL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first {
            openPanel.directoryURL = applicationsURL
        }
        openPanel.title = String(localized: "Choose Applications")
        openPanel.prompt = String(localized: "Add")
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.allowedContentTypes = [.applicationBundle]

        guard openPanel.runModal() == .OK else { return }
        openPanel.urls.forEach(addApplication(from:))
    }

    func addApplication(from url: URL) {
        guard let bundle = Bundle(url: url) else {
            showError(message: String(localized: "Could not read the application at \(url.lastPathComponent)."))
            return
        }
        guard let bundleId = bundle.bundleIdentifier else {
            showError(message: String(localized: "\(url.lastPathComponent) has no bundle identifier."))
            return
        }
        guard !isAppManaged(bundleIdentifier: bundleId) else {
            Logger.info("Skipping \(bundleId); already managed.")
            return
        }

        let appName = FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "", options: [.anchored, .backwards])
        let category = bundle.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String ?? ""
        let finalCategory = category.isEmpty ? Constants.categoryOther : category

        let bookmarkData: Data
        do {
            bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            showError(message: String(localized: "Could not save access to \(appName): \(error.localizedDescription)"))
            return
        }

        appStore.addApp(name: appName, bundleIdentifier: bundleId, bookmark: bookmarkData, category: finalCategory)
    }

    func isAppManaged(bundleIdentifier: String) -> Bool {
        appStore.managedApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }

    // MARK: - Login Items

    func refreshLoginItems() {
        loginItemPaths = Set(LoginItemHelper.snapshotLoginItemURLs().map(\.path))
    }

    func isLoginItem(app: ManagedApp) -> Bool {
        guard !loginItemPaths.isEmpty else { return false }
        return app.withSecurityScopedURL { loginItemPaths.contains($0.path) } ?? false
    }

    // MARK: - Icons

    func icon(for app: ManagedApp) -> NSImage {
        if let cached = iconCache[app.id] {
            return cached
        }
        let icon = app.withSecurityScopedURL { NSWorkspace.shared.icon(forFile: $0.path) }
            ?? NSImage(systemSymbolName: "questionmark.app.dashed", accessibilityDescription: nil)
            ?? NSImage()
        iconCache[app.id] = icon
        return icon
    }

    // MARK: - Store Changes

    private func storeDidChange(_ apps: [ManagedApp]) {
        let ids = Set(apps.map(\.id))
        iconCache = iconCache.filter { ids.contains($0.key) }

        // Fall back to "All Apps" when the selected category's last app is removed.
        if let selectedCategory, selectedCategory != Constants.categoryAllApps,
           !apps.contains(where: { $0.category == selectedCategory }) {
            self.selectedCategory = Constants.categoryAllApps
        }
    }

    // MARK: - Error Handling

    func showError(message: String) {
        alertMessage = message
        showingAlert = true
        Logger.error(message)
    }
}
