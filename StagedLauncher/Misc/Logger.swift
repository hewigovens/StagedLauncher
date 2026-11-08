import Foundation
import os

/// Thin wrapper over unified logging. View logs with:
/// `log stream --predicate 'subsystem == "dev.hewig.StagedLauncher"'`
enum Logger {
    private static let log = os.Logger(
        subsystem: Bundle.main.bundleIdentifier ?? Constants.selfBundleId,
        category: "app"
    )

    // Messages contain app names and paths only, so they are logged as public.
    static func info(_ message: String) {
        log.notice("\(message, privacy: .public)")
    }

    static func warning(_ message: String) {
        log.warning("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        log.error("\(message, privacy: .public)")
    }
}
