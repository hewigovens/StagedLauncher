import Foundation

enum Logger {

    private static var logFileURL: URL? = {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            print("Logger Error: Could not get bundle identifier.")
            return nil
        }
        do {
            let appSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let appLogDirectory = appSupportURL.appendingPathComponent(bundleIdentifier)
            try FileManager.default.createDirectory(at: appLogDirectory, withIntermediateDirectories: true, attributes: nil)
            return appLogDirectory.appendingPathComponent("app.log")
        } catch {
            print("Logger Error: Could not create log file directory: \(error)")
            return nil
        }
    }()

    private static func writeToFile(_ message: String) {
        guard let url = logFileURL else { return }

        let formattedMessage = "\(Date().ISO8601Format()): \(message)\n"
        guard let data = formattedMessage.data(using: .utf8) else { return }

        do {
            let fileHandle = try FileHandle(forWritingTo: url)
            try fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
            try fileHandle.close()
        } catch {
            // If file doesn't exist or other write error, try writing directly
            do {
                try data.write(to: url, options: .atomic)
            } catch let writeError {
                // Use print here as a last resort if logger setup fails
                print("Logger Error: Failed to write to log file \(url): \(writeError)")
            }
        }
    }

    static func info(_ message: String) {
        #if DEBUG
        print("INFO: \(message)")
        #else
        writeToFile("INFO: \(message)")
        #endif
    }

    static func warning(_ message: String) {
        #if DEBUG
        print("WARN: \(message)")
        #else
        writeToFile("WARN: \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("ERROR: \(message)")
        #else
        writeToFile("ERROR: \(message)")
        #endif
    }
}
