import SwiftUI
import SwiftData
import DesignKit

struct AppBootstrapView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @AppStorage("onboardingStateV1") private var onboardingStateRaw = ""

    @State private var isReady = false
    @State private var bootstrapError: String?
    @State private var reloadToken = UUID()
    @State private var isUITestOnboardingActive = ProcessInfo.processInfo.arguments.contains("-uiTestingShowOnboarding")
    @State private var isShowingEntry = true
    @State private var showsEntryProgress = false

    private let bootstrapService = BootstrapService()

    var body: some View {
        ZStack {
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
                }
            }

            if isShowingEntry {
                AppEntryView(showsProgress: showsEntryProgress)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task(id: reloadToken) {
            await bootstrap()
        }
        .task(id: reloadToken) {
            await revealProgressIfStartupIsSlow()
        }
    }

    private func bootstrap() async {
        bootstrapError = nil
        isReady = false
        isShowingEntry = true
        showsEntryProgress = false

        await applyUITestBootstrapDelayIfNeeded()

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
            await dismissEntry()
        } catch {
            bootstrapError = error.localizedDescription
            await dismissEntry()
        }
    }

    private func revealProgressIfStartupIsSlow() async {
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled, !isReady, bootstrapError == nil else { return }
        showsEntryProgress = true
    }

    private func dismissEntry() async {
        await Task.yield()
        withAnimation(reduceMotion ? nil : theme.motion.ease) {
            isShowingEntry = false
        }
    }

    private func applyUITestBootstrapDelayIfNeeded() async {
        guard
            let rawDelay = ProcessInfo.processInfo.environment["UI_TEST_BOOTSTRAP_DELAY"],
            let delay = Double(rawDelay),
            delay > 0
        else { return }

        try? await Task.sleep(for: .seconds(delay))
    }

    private var onboardingState: OnboardingState {
        OnboardingState(rawValue: onboardingStateRaw) ?? .completed
    }

    private var theme: Theme {
        themeManager.theme(for: colorScheme)
    }
}
