import Foundation

/// Represents an application managed by StagedLauncher.
struct ManagedApp: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var bundleIdentifier: String
    /// Security-scoped bookmark to the app bundle, required to launch it from the sandbox.
    var bookmarkData: Data?
    var delaySeconds: Int = 180
    var isEnabled: Bool = true
    /// Raw `LSApplicationCategoryType` value, or `Constants.categoryOther`.
    var category: String

    // MARK: - Delay Options

    static let delayOptions: [Int] = [0, 30, 60, 120, 180, 300, 600]

    static func formatDelay(_ seconds: Int) -> String {
        guard seconds > 0 else { return String(localized: "No Delay") }
        return Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .abbreviated))
    }

    // MARK: - Bookmark Access

    /// Resolves the bookmark and runs `body` while the security-scoped URL is accessible.
    /// Returns `nil` when there is no bookmark or it cannot be resolved or accessed.
    func withSecurityScopedURL<T>(_ body: (URL) throws -> T) rethrows -> T? {
        guard let bookmarkData else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            Logger.error("Could not resolve bookmark for \(name).")
            return nil
        }
        if isStale {
            Logger.warning("Bookmark for \(name) is stale.")
        }
        guard url.startAccessingSecurityScopedResource() else {
            Logger.error("Could not access security-scoped URL for \(name).")
            return nil
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return try body(url)
    }

    static func new(name: String, bundleIdentifier: String, bookmark: Data?, category: String) -> ManagedApp {
        ManagedApp(id: UUID(), name: name, bundleIdentifier: bundleIdentifier, bookmarkData: bookmark, category: category)
    }
}
