import SwiftUI
import AppKit

struct ContentView: View {
    @ObservedObject var appStore: ManagedAppStore
    @ObservedObject var viewModel: ContentViewModel
    @State private var showingRunningAppsSheet = false
    @State private var selectedAppId: ManagedApp.ID? = nil

    init(appStore: ManagedAppStore, viewModel: ContentViewModel) {
        self.appStore = appStore
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationSplitView {
            CategoryListView(viewModel: viewModel)
        } detail: {
            VStack {
                if viewModel.filteredApps.isEmpty {
                    Spacer()
                    Text("Tap the ‘+’ in the top-right corner to add your first app!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.top, -10)
                    Spacer()
                } else {
                    List(selection: $selectedAppId) {
                        Group {
                            ForEach(viewModel.filteredApps.indices, id: \.self) { index in
                                let app = viewModel.filteredApps[index]
                                if let originalIndex = appStore.managedApps.firstIndex(where: { $0.id == app.id }) {
                                    ManagedAppCell(
                                        app: $appStore.managedApps[originalIndex],
                                        viewModel: viewModel,
                                        appStore: appStore,
                                        index: index
                                    )
                                    .tag(app.id)
                                }
                            }
                            .onDelete(perform: viewModel.removeFilteredApps)
                        }
                        .id(viewModel.selectedCategory)
                    }
                    .scrollContentBackground(.hidden)
                    .background(VisualEffectView(material: .contentBackground))
                    .listRowSeparator(.visible)
                    .listStyle(.inset)
                }
            }
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
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingRunningAppsSheet) {
                RunningAppsSheet(contentViewModel: viewModel)
            }
            .overlay(alignment: .bottom) {
                footerView
            }
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(title: Text("Error"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        
    }
    
    private var footerView: some View {
        HStack {
            Spacer()
            Button(action: {
                NSWorkspace.shared.open(URL(string: Constants.sponsorLink)!)
            }) {
                Label("Sponsor", systemImage: "heart.circle.fill")
                    .font(.footnote)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            Divider()
                .frame(height: 12)
                .padding(.horizontal, 8)
            Button(action : {
                NSWorkspace.shared.open(URL(string: Constants.githubLink)!)
            }) {
                Text("Version \(getAppVersion())")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(Divider(), alignment: .top)
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
