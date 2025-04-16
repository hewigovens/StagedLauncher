import AppKit
import SwiftUI

struct RunningApp: Identifiable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    let icon: NSImage
    let url: URL
}
