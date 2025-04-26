import SwiftUI

struct ContentView: View {
    // Observe the AppStore passed from StagedLauncherApp
    @ObservedObject var appStore: ManagedAppStore
    // ViewModel is now passed in and observed
    @ObservedObject var viewModel: ContentViewModel
    // State to control the running apps sheet presentation
    @State private var showingRunningAppsSheet = false
    // State to track the selected app in the detail list
    @State private var selectedAppId: ManagedApp.ID? = nil

    // Updated initializer to accept both AppStore and ContentViewModel
    init(appStore: ManagedAppStore, viewModel: ContentViewModel) {
        self.appStore = appStore
        self.viewModel = viewModel
    }

    var body: some View {
        // Use NavigationSplitView for Sidebar + Detail layout
        NavigationSplitView {
            // Use the extracted CategoryListView for the sidebar
            CategoryListView(viewModel: viewModel)
        } detail: {
            // Wrap content in a VStack to hold either List or Placeholder
            VStack {
                if viewModel.filteredApps.isEmpty {
                    Spacer()
                    Text("Tap the ‘+’ in the top-right corner to add your first app!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, -10)
                    Spacer()
                } else {
                    // --- Detail: Filtered App List ---
                    // Add selection binding to the List
                    List(selection: $selectedAppId) {
                        // Wrap ForEach in a Group and apply .id to the Group
                        Group {
                            ForEach(viewModel.filteredApps.indices, id: \.self) { index in
                                let app = viewModel.filteredApps[index]
                                // Find the binding for the specific app in the original AppStore array
                                if let originalIndex = appStore.managedApps.firstIndex(where: { $0.id == app.id }) {
                                    ManagedAppCell(
                                        app: $appStore.managedApps[originalIndex],
                                        viewModel: viewModel,
                                        appStore: appStore,
                                        index: index
                                    )
                                    // Tag the row with the app's ID for selection
                                    .tag(app.id)
                                }
                            }
                            .onDelete(perform: viewModel.removeFilteredApps) // Need a new method for deleting from filtered list
                        }
                        .id(viewModel.selectedCategory) // Apply ID to the Group
                    }
                    // Add translucent background material (apply only when list is shown)
                    .background(.ultraThinMaterial)
                }
            }
            // Use the formatted category name for the title
            .navigationTitle(viewModel.formatCategoryName(viewModel.selectedCategory ?? "All Apps"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.presentOpenPanel()
                    } label: {
                        Label("Add App", systemImage: "plus.app")
                    }
                }
                // Toolbar button to show running apps sheet
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingRunningAppsSheet = true
                    } label: {
                        Label("Add Application from Running", systemImage: "iphone.app.switcher")
                    }
                }
                // Toolbar item using SettingsLink
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            // Sheet modifier to present the running apps list
            .sheet(isPresented: $showingRunningAppsSheet) {
                RunningAppsSheet(contentViewModel: viewModel)
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}
