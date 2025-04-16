import SwiftUI

struct ManagedAppCell: View {
    // Binding to the specific app this cell represents
    @Binding var app: ManagedApp
    // ObservedObject reference to the ViewModel for actions/helpers
    @ObservedObject var viewModel: ContentViewModel
    // Direct reference to AppStore needed for saving
    @ObservedObject var appStore: AppStore
    // Index of the row for alternating background
    var index: Int

    // State for controlling the login item info popover
    @State private var showingLoginItemInfo = false

    var body: some View {
        // The HStack layout moved from ContentView
        HStack(spacing: 10) { // Add spacing between elements
            Image(nsImage: viewModel.getAppIcon(for: app.bookmarkData))
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48) // Increased icon size

            // Group name and warning icon
            HStack(spacing: 4) {
                Text(app.name)

                // Show warning if the app is already a system login item
                if viewModel.isLoginItem(app: app) {
                    // Button to toggle the popover
                    Button {
                        showingLoginItemInfo = true
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain) // Make it look like a plain image
                    // Popover attached to the button's label (the Image)
                    .popover(isPresented: $showingLoginItemInfo, arrowEdge: .bottom) {
                        Text("This app is already in System Login Items.")
                            .padding()
                    }
                }
            }

            Spacer() // Pushes subsequent views to the right

            // Replace TextField with Picker for delay options
            Picker("Delay", selection: $app.delaySeconds) {
                ForEach(ManagedApp.delayOptions, id: \.self) { seconds in
                    Text(ManagedApp.formatDelay(seconds)).tag(seconds)
                }
            }
            .labelsHidden() // Optionally hide the "Delay" label if space is tight
            .frame(width: 80) // Give the picker a fixed width
            // Save when delay changes
            .onChange(of: app.delaySeconds) { appStore.saveApps() }

            Toggle("Enabled", isOn: $app.isEnabled)
                .labelsHidden()
                // Save when toggle changes
                .onChange(of: app.isEnabled) { appStore.saveApps() }

            Button {
                viewModel.removeApp(id: app.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4) // Add vertical padding to each row
    }
}

// Optional: Add a preview provider
struct ManagedAppCell_Previews: PreviewProvider {
    static var appStore: AppStore = {
        let dummyAppStore = AppStore()
        dummyAppStore.addApp(name: "Preview App", bundleIdentifier: "com.example.preview", bookmark: nil, category: "Other")
        return dummyAppStore
    }()

    static var previews: some View {
        let appBinding = Binding<ManagedApp>(
            get: { Self.appStore.managedApps[0] },
            set: { Self.appStore.managedApps[0] = $0 }
        )
        ManagedAppCell(
            app: appBinding,
            viewModel: ContentViewModel(appStore: Self.appStore),
            appStore: Self.appStore, // Pass AppStore for saving
            index: 0 // Provide a dummy index for preview
        )
        .padding() // Add padding around the cell for preview visibility
        .frame(width: 350) // Give it a reasonable width for preview
    }
}
