import SwiftUI

struct ContentView: View {
    // Directly observe the AppStore for list data changes
    @ObservedObject var appStore: AppStore
    // ViewModel now also manages filtering state
    @StateObject private var viewModel: ContentViewModel
    // State to control the running apps sheet presentation
    @State private var showingRunningAppsSheet = false
    // State to track the selected app in the detail list
    @State private var selectedAppId: ManagedApp.ID? = nil

    init(appStore: AppStore) {
        self.appStore = appStore
        _viewModel = StateObject(wrappedValue: ContentViewModel(appStore: appStore))
    }

    var body: some View {
        // Use NavigationSplitView for Sidebar + Detail layout
        NavigationSplitView {
            // Use the extracted CategoryListView for the sidebar
            CategoryListView(viewModel: viewModel)
        } detail: {
            // --- Detail: Filtered App List ---
            // Add selection binding to the List
            List(selection: $selectedAppId) {
                // Wrap ForEach in a Group and apply .id to the Group
                Group {
                    ForEach(viewModel.filteredApps.indices, id: \.self) { index in
                        let app = viewModel.filteredApps[index]
                        // Find the binding for the specific app in the original AppStore array
                        if let originalIndex = appStore.managedApps.firstIndex(where: { $0.id == app.id }) {
                            ManagedAppCell(app: $appStore.managedApps[originalIndex], 
                                           viewModel: viewModel, 
                                           appStore: appStore, 
                                           index: index)
                                // Tag the row with the app's ID for selection
                                .tag(app.id)
                        }
                    }
                    .onDelete(perform: viewModel.removeFilteredApps) // Need a new method for deleting from filtered list
                }
                .id(viewModel.selectedCategory) // Apply ID to the Group
            }
            // Add translucent background material
            .background(.ultraThinMaterial)
            // Use the formatted category name for the title
            .navigationTitle(viewModel.formatCategoryName(viewModel.selectedCategory ?? "All Apps"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.presentOpenPanel()
                    } label: {
                        Label("Add App", systemImage: "plus")
                    }
                }
                // Toolbar button to show running apps sheet
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingRunningAppsSheet = true
                    } label: {
                        Label("Add Application from Running", systemImage: "plus.rectangle.on.rectangle")
                    }
                }
                // Toolbar item using SettingsLink
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink {
                        Label("Settings", systemImage: "gearshape.fill")
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

// Updated Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(appStore: AppStore())
    }
}
