import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var showingRunningAppsSheet = false
    @State private var selectedAppIDs: Set<ManagedApp.ID> = []
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationSplitView {
            CategoryListView(viewModel: viewModel)
        } detail: {
            detail
                .navigationTitle(viewModel.formatCategoryName(viewModel.selectedCategory ?? Constants.categoryAllApps))
                .toolbar { toolbarContent }
                .safeAreaInset(edge: .bottom, spacing: 0) { footerView }
        }
        .sheet(isPresented: $showingRunningAppsSheet) {
            RunningAppsSheet(contentViewModel: viewModel)
        }
        .alert("Something Went Wrong", isPresented: $viewModel.showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            MenuBarService.shared.openMainWindow = { openWindow(id: Constants.mainWindowID) }
            viewModel.refreshLoginItems()
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if viewModel.filteredApps.isEmpty {
            ContentUnavailableView {
                Label("No Apps Yet", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("Add apps to launch them a little while after you log in, instead of all at once.")
            } actions: {
                Button("Add App…") { viewModel.presentOpenPanel() }
                    .buttonStyle(.borderedProminent)
                Button("Add from Running Apps…") { showingRunningAppsSheet = true }
            }
        } else {
            List(selection: $selectedAppIDs) {
                ForEach(viewModel.filteredApps) { app in
                    ManagedAppCell(app: viewModel.binding(for: app), viewModel: viewModel)
                        .tag(app.id)
                }
            }
            .listStyle(.inset)
            .contextMenu(forSelectionType: ManagedApp.ID.self) { ids in
                if ids.count == 1, let app = viewModel.filteredApps.first(where: { ids.contains($0.id) }) {
                    Button("Show in Finder") { viewModel.revealInFinder(app) }
                    Divider()
                }
                if !ids.isEmpty {
                    Button("Remove", role: .destructive) { remove(ids) }
                }
            }
            .onDeleteCommand { remove(selectedAppIDs) }
        }
    }

    private func remove(_ ids: Set<ManagedApp.ID>) {
        ids.forEach(viewModel.removeApp(id:))
        selectedAppIDs.subtract(ids)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                showingRunningAppsSheet = true
            } label: {
                Label("Add from Running Apps", systemImage: "macwindow.badge.plus")
            }
            .help("Add from Running Apps")

            Button {
                viewModel.presentOpenPanel()
            } label: {
                Label("Add App", systemImage: "plus")
            }
            .help("Add App")
            .keyboardShortcut("o", modifiers: .command)

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .help("Settings")
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack(spacing: 12) {
            Spacer()
            Link(destination: URL(string: Constants.sponsorLink)!) {
                Label("Sponsor", systemImage: "heart")
            }
            Link("Version \(appVersion)", destination: URL(string: Constants.githubLink)!)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
