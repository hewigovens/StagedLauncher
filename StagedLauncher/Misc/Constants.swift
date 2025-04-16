import Foundation

/// Centralized constants for the application.
enum Constants {
    /// UserDefaults key for storing the 'show menu bar icon' setting.
    static let showMenuBarIconKey = "showMenuBarIcon"

    /// UserDefaults key for storing the list of managed applications.
    static let managedAppsUserDefaultsKey = "managedApps"

    static let sessionLoginItemsKey = "com.apple.LSSharedFileList.SessionLoginItems" as CFString

    static let selfBundleId = "dev.hewig.StagedLauncher"

    /// The display string for the category representing all applications.
    static let categoryAllApps = "All Apps"

    static let categoryOther = "Other"
}
