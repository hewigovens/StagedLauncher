import AppKit
import SwiftUI

// Create a delegate to hook into App Lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    // We need access to the LaunchManager instance created in the App struct
    // This will be injected from StagedLauncherApp
    var launchManager: LaunchManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Logger.info("AppDelegate: Application finished launching.")
        // Start the launch manager once the app is ready
        launchManager?.startMonitoring()
        
        // Setup the menu bar icon manager (now handles initial activation policy)
        MenuBarManager.shared.setupMenuBar()
    }

    func applicationWillTerminate(_ notification: Notification) {
        Logger.info("AppDelegate: Application will terminate.")
        // Clean up timers when the app quits
        launchManager?.stopMonitoring()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
