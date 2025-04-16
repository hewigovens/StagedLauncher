import Foundation

/// A protocol defining the requirements for an object that can handle displaying errors to the user.
protocol ErrorPresentable: AnyObject {
    /// Displays an error message to the user.
    /// - Parameter message: The error message string to display.
    @MainActor
    func showError(message: String)
}
