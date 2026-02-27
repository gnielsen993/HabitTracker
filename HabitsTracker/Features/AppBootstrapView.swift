import SwiftUI
import SwiftData

struct AppBootstrapView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isReady = false
    @State private var bootstrapError: String?
    @State private var reloadToken = UUID()

    private let bootstrapService = BootstrapService()

    var body: some View {
        Group {
            if isReady {
                RootTabView()
            } else if let bootstrapError {
                ContentUnavailableView(
                    "Setup Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(bootstrapError)
                )
                .overlay(alignment: .bottom) {
                    Button("Retry") { reloadToken = UUID() }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, 48)
                }
            } else {
                ProgressView("Preparing habit data…")
            }
        }
        .task(id: reloadToken) {
            await bootstrap()
        }
    }

    private func bootstrap() async {
        bootstrapError = nil
        isReady = false

        do {
            try bootstrapService.bootstrapIfNeeded(context: modelContext)
            isReady = true
        } catch {
            bootstrapError = error.localizedDescription
        }
    }
}
