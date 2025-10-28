import SwiftUI

struct ManagedAppCell: View {
    @Binding var app: ManagedApp
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var appStore: ManagedAppStore
    var index: Int

    @State private var showingLoginItemInfo = false

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: viewModel.getAppIcon(for: app.bookmarkData))
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            HStack(spacing: 4) {
                Text(app.name)

                if viewModel.isLoginItem(app: app) {
                    Button {
                        showingLoginItemInfo = true
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingLoginItemInfo, arrowEdge: .bottom) {
                        Text("This app is already in System Login Items.")
                            .padding()
                    }
                }
            }

            Spacer()

            Picker("Delay", selection: $app.delaySeconds) {
                ForEach(ManagedApp.delayOptions, id: \.self) { seconds in
                    Text(ManagedApp.formatDelay(seconds)).tag(seconds)
                }
            }
            .labelsHidden()
            .frame(width: 80)
            .onChange(of: app.delaySeconds) { _, _ in appStore.saveApps() }

            Toggle("Enabled", isOn: $app.isEnabled)
                .labelsHidden()
                .onChange(of: app.isEnabled) { _, _ in appStore.saveApps() }

            Button {
                viewModel.removeApp(id: app.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
        }
        .padding(.vertical, 4)
    }
}
