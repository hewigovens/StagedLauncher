import SwiftUI

struct SettingsView: View {
    @AppStorage(Constants.showMenuBarIconKey) private var showMenuBarIcon = false
    @AppStorage(Constants.enableNotificationsKey) private var enableNotifications = false
    @AppStorage(Constants.enabledQuitSelfKey) private var enabledQuitSelf = false

    @ObservedObject private var loginItemService = LoginItemService.shared

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { loginItemService.isEnabled },
                    set: { loginItemService.setEnabled($0) }
                ))
                if loginItemService.status == .requiresApproval {
                    approvalNote
                }
                if let error = loginItemService.lastError {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
                Toggle("Quit after all apps have launched", isOn: $enabledQuitSelf)
            } footer: {
                Text("Staged Launcher needs to start at login to launch your apps on schedule.")
                    .settingsFooter()
            }

            Section {
                Toggle("Show in menu bar instead of Dock", isOn: $showMenuBarIcon)
                    .onChange(of: showMenuBarIcon) { _, newValue in
                        MenuBarService.shared.updateMenuBarIconVisibility(shouldShow: newValue)
                    }
                Toggle("Notify when an app launches", isOn: $enableNotifications)
                    .onChange(of: enableNotifications) { _, newValue in
                        if newValue {
                            NotificationService.shared.requestAuthorizationIfNeeded()
                        }
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { loginItemService.refresh() }
    }

    private var approvalNote: some View {
        HStack {
            Label("Needs approval in System Settings", systemImage: "exclamationmark.triangle.fill")
                .font(.callout)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.multicolor)
            Spacer()
            Button("Open Login Items…") { loginItemService.openSystemSettings() }
        }
    }
}

private extension View {
    func settingsFooter() -> some View {
        font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
