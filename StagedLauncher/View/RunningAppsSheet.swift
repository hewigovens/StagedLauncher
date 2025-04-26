import SwiftUI

struct RunningAppsSheet: View {
    // ViewModel to fetch running apps
    @StateObject private var runningAppsViewModel = RunningAppsViewModel()
    // ViewModel of the ContentView to add the selected app
    @ObservedObject var contentViewModel: ContentViewModel
    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            Text("Add from Running Applications")
                .font(.title2)
                .padding()

            List {
                ForEach(runningAppsViewModel.runningApps) { app in
                    HStack {
                        Image(nsImage: app.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        Text(app.name)
                        Spacer()
                        // Only show Add button if the app isn't already managed
                        if !contentViewModel.isAppManaged(bundleIdentifier: app.bundleIdentifier) {
                            Button("Add") {
                                contentViewModel.addApplication(from: app.url)
                                // Optionally dismiss the sheet after adding
                                // dismiss()
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Text("Added")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Button("Refresh List") {
                    runningAppsViewModel.fetchRunningApps()
                }
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 400)
        .onAppear {
            // Fetch apps when the sheet appears
            runningAppsViewModel.fetchRunningApps()
        }
    }
}

// Preview
#Preview {
    // Need to inject a ContentViewModel
    let appStore = ManagedAppStore()
    // Add a dummy app to check the 'Added' state
    appStore.managedApps.append(ManagedApp.new(name: "Dummy", bundleIdentifier: "com.apple.finder", bookmark: nil, category: "Other"))
    let contentViewModel = ContentViewModel(appStore: appStore)

    return RunningAppsSheet(contentViewModel: contentViewModel)
}
