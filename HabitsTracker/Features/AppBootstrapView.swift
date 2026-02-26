import SwiftUI
import SwiftData

struct AppBootstrapView: View {
    @Environment(\.modelContext) private var modelContext

    private let bootstrapService = BootstrapService()

    var body: some View {
        RootTabView()
            .task {
                do {
                    try bootstrapService.bootstrapIfNeeded(context: modelContext)
                } catch {
                    assertionFailure("Bootstrap failed: \(error)")
                }
            }
    }
}
