import AppKit

struct RunningApp: Identifiable {
    var id: String { bundleIdentifier }
    let name: String
    let bundleIdentifier: String
    let icon: NSImage
    let url: URL
}
