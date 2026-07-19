import SwiftUI
import SwiftData
import DesignKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    let isFirstRun: Bool
    let onFinish: () -> Void

    @State private var page = 0
    @State private var completedDemo = false
    @State private var selectedDomainIDs: Set<UUID> = []
    @State private var didPrepareSelection = false
    @State private var saveError: String?

    private let lastPage = 3

    private var theme: Theme {
        themeManager.theme(for: colorScheme)
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    OnboardingWelcomePage(theme: theme)
                        .tag(0)

                    OnboardingHabitPage(
                        isCompleted: $completedDemo,
                        theme: theme,
                        reduceMotion: reduceMotion
                    )
                    .tag(1)

                    OnboardingLifePage(theme: theme)
                        .tag(2)

                    OnboardingAreasPage(
                        domains: domains,
                        selectedDomainIDs: $selectedDomainIDs,
                        theme: theme,
                        colorScheme: colorScheme
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : theme.motion.ease, value: page)

                footer
            }
        }
        .task { prepareSelectionIfNeeded() }
        .alert("Couldn’t Save Areas", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "Please try again.")
        }
    }

    private var topBar: some View {
        HStack {
            Text("HABITS")
                .font(theme.typography.caption.weight(.bold))
                .tracking(theme.spacing.xs)
                .foregroundStyle(theme.colors.textSecondary)

            Spacer()

            Button(isFirstRun ? "Skip" : "Close", action: onFinish)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)
                .frame(minHeight: 44)
                .accessibilityHint(isFirstRun ? "Uses the starter setup and opens Today" : "Returns to Settings")
        }
        .padding(.horizontal, theme.spacing.l)
        .padding(.top, theme.spacing.s)
    }

    private var footer: some View {
        VStack(spacing: theme.spacing.l) {
            HStack(spacing: theme.spacing.s) {
                ForEach(0...lastPage, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? theme.colors.accentPrimary : theme.colors.border)
                        .frame(
                            width: index == page ? theme.spacing.xl : theme.spacing.s,
                            height: theme.spacing.xs
                        )
                        .animation(reduceMotion ? nil : theme.motion.ease, value: page)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(page + 1) of \(lastPage + 1)")

            DKButton(
                primaryButtonTitle,
                theme: theme,
                isEnabled: page != lastPage || !selectedDomainIDs.isEmpty,
                action: advance
            )
        }
        .padding(.horizontal, theme.spacing.l)
        .padding(.bottom, theme.spacing.l)
    }

    private var primaryButtonTitle: String {
        switch page {
        case 0: "See how it feels"
        case 1: completedDemo ? "Keep going" : "Continue"
        case 2: "Make it yours"
        default: isFirstRun ? "Enter your day" : "Save areas"
        }
    }

    private func advance() {
        guard page == lastPage else {
            if reduceMotion {
                page += 1
            } else {
                withAnimation(theme.motion.ease) { page += 1 }
            }
            return
        }

        do {
            for domain in domains {
                domain.isFocused = selectedDomainIDs.contains(domain.id)
            }
            try modelContext.save()
            onFinish()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func prepareSelectionIfNeeded() {
        guard !didPrepareSelection, !domains.isEmpty else { return }
        didPrepareSelection = true

        if isFirstRun {
            let recommended = Set(["Productivity", "Health", "Learning", "Personal"])
            selectedDomainIDs = Set(domains.filter { recommended.contains($0.name) }.map(\.id))
        } else {
            selectedDomainIDs = Set(domains.filter(\.isFocused).map(\.id))
        }

        if selectedDomainIDs.isEmpty, let first = domains.first {
            selectedDomainIDs.insert(first.id)
        }
    }
}
