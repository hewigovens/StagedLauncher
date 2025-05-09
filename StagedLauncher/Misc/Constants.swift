import Foundation

/// Centralized constants for the application.
enum Constants {
    /// UserDefaults key for storing the 'show menu bar icon' setting.
    static let showMenuBarIconKey = "showMenuBarIcon"
    /// UserDefaults key for storing the list of managed applications.
    static let managedAppsUserDefaultsKey = "managedApps"

    /// CFString key for session login items.
    static let sessionLoginItemsKey = "com.apple.LSSharedFileList.SessionLoginItems" as CFString

    /// The bundle identifier of the application.
    static let selfBundleId = "dev.hewig.StagedLauncher"

    /// The display string for the category representing all applications.
    static let categoryAllApps = "All Apps"

    /// The display string for the category representing other applications.
    static let categoryOther = "Other"

    /// UserDefaults key for storing the notification preference.
    static let enableNotificationsKey = "enableLaunchNotifications"

    static let enabledQuitSelfKey = "enableQuitSelf"
    
    static let sponsorLink = "https://github.com/sponsors/hewigovens?frequency=one-time"
    
    static let githubLink = "https://github.com/hewigovens/StagedLauncher"
}
