import Foundation

/// Represents an application managed by StagedLauncher.
struct ManagedApp: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var bundleIdentifier: String // Using Bundle ID is generally preferred
    var bookmarkData: Data? // Store bookmark data instead of raw URL
    var delaySeconds: Int = 180 // Default to 3 minutes
    var isEnabled: Bool = true
    var category: String // Add category property

    // --- Delay Options ---
    static let delayOptions: [Int] = [0, 30, 60, 120, 180, 300, 600] // In seconds

    static func formatDelay(_ seconds: Int) -> String {
        switch seconds {
        case 0: return "None"
        case 60: return "1 Min"
        case let s where s < 60: return "\(s) Sec"
        default: return "\(seconds / 60) Min"
        }
    }
    // --- End Delay Options ---

    // Computed property to resolve the URL from bookmark data
    var resolvedURL: URL? {
        guard let data = bookmarkData else { return nil }
        var isStale = false
        let url = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
        // Handle stale bookmark if necessary, e.g., try to refresh it
        // For simplicity now, we just return the resolved URL or nil
        return url
    }

    // Static func for easy creation - accepts bookmark data
    static func new(name: String, bundleIdentifier: String, bookmark: Data?, category: String) -> ManagedApp {
        ManagedApp(id: UUID(), name: name, bundleIdentifier: bundleIdentifier, bookmarkData: bookmark, category: category)
    }
}
