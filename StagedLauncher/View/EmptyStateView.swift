import SwiftUI

/// Shown in the detail area while no apps are managed.
struct EmptyStateView: View {
    let addApp: () -> Void
    let addFromRunningApps: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(.tint)
                    .padding(.bottom, 4)
                    .accessibilityHidden(true)
                Text("No Apps Yet")
                    .font(.title2.weight(.semibold))
                Text("Stage the apps you open at login, so they launch one after another instead of all at once.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button(action: addApp) {
                    Label("Add App…", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                Button("Add from Running Apps…", action: addFromRunningApps)
            }
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: 400)
    }
}
