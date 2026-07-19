import SwiftUI
import SwiftData

struct AppBootstrapView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage("onboardingStateV1") private var onboardingStateRaw = ""

    @State private var isReady = false
    @State private var bootstrapError: String?
    @State private var reloadToken = UUID()
    @State private var isUITestOnboardingActive = ProcessInfo.processInfo.arguments.contains("-uiTestingShowOnboarding")

    private let bootstrapService = BootstrapService()

    var body: some View {
        Group {
            if isReady {
                if onboardingState == .pending || isUITestOnboardingActive {
                    OnboardingView(isFirstRun: true) {
                        onboardingStateRaw = OnboardingState.completed.rawValue
                        isUITestOnboardingActive = false
                    }
                } else {
                    RootTabView()
                }
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
            let existingDomains = try modelContext.fetch(FetchDescriptor<Domain>())
            let hasExistingData = !existingDomains.isEmpty
            let resolvedOnboarding = OnboardingState.resolved(
                storedValue: onboardingStateRaw,
                hasExistingData: hasExistingData
            )
            onboardingStateRaw = resolvedOnboarding.rawValue

            try bootstrapService.bootstrapIfNeeded(context: modelContext)
            isReady = true
        } catch {
            bootstrapError = error.localizedDescription
        }
    }

    private var onboardingState: OnboardingState {
        OnboardingState(rawValue: onboardingStateRaw) ?? .completed
    }
}
