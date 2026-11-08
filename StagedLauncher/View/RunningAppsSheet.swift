import SwiftUI

struct RunningAppsSheet: View {
    @StateObject private var runningAppsViewModel = RunningAppsViewModel()
    @ObservedObject var contentViewModel: ContentViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add from Running Apps")
                    .font(.headline)
                Spacer()
                Button {
                    runningAppsViewModel.fetchRunningApps()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .help("Refresh")
            }
            .padding()

            Divider()

            if runningAppsViewModel.runningApps.isEmpty {
                ContentUnavailableView("No Running Apps", systemImage: "macwindow", description: Text("Open the apps you want to stage, then refresh."))
            } else {
                List(runningAppsViewModel.runningApps) { app in
                    HStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)
                        Text(app.name)
                        Spacer()
                        if contentViewModel.isAppManaged(bundleIdentifier: app.bundleIdentifier) {
                            Label("Added", systemImage: "checkmark")
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Add") {
                                contentViewModel.addApplication(from: app.url)
                            }
                            .accessibilityLabel("Add \(app.name)")
                        }
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 420, height: 460)
        .onAppear {
            runningAppsViewModel.fetchRunningApps()
        }
    }
}

#Preview {
    let appStore = ManagedAppStore()
    appStore.managedApps.append(ManagedApp.new(name: "Dummy", bundleIdentifier: "com.apple.finder", bookmark: nil, category: "Other"))
    return RunningAppsSheet(contentViewModel: ContentViewModel(appStore: appStore))
}
