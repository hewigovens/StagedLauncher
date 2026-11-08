import SwiftUI

struct ManagedAppCell: View {
    @Binding var app: ManagedApp
    @ObservedObject var viewModel: ContentViewModel

    @State private var showingLoginItemInfo = false

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: viewModel.icon(for: app))
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .opacity(app.isEnabled ? 1 : 0.5)
                .accessibilityHidden(true)

            HStack(spacing: 4) {
                Text(app.name)
                    .foregroundStyle(app.isEnabled ? .primary : .secondary)
                    .lineLimit(1)

                if viewModel.isLoginItem(app: app) {
                    Button {
                        showingLoginItemInfo = true
                    } label: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Also in System Login Items")
                    .accessibilityLabel("Also in System Login Items")
                    .popover(isPresented: $showingLoginItemInfo, arrowEdge: .bottom) {
                        Text("This app is also in System Login Items, so macOS launches it right away. Remove it there to stage its launch.")
                            .frame(width: 260)
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
            .fixedSize()
            .disabled(!app.isEnabled)
            .help("Delay after login")
            .accessibilityLabel("Launch delay for \(app.name)")

            Toggle("Launch \(app.name) at login", isOn: $app.isEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .help(app.isEnabled ? "Enabled" : "Disabled")

            Button(role: .destructive) {
                viewModel.removeApp(id: app.id)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Remove")
            .accessibilityLabel("Remove \(app.name)")
        }
        .padding(.vertical, 4)
    }
}
