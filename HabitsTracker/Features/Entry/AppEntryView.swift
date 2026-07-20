import SwiftUI
import DesignKit

struct AppEntryView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let showsProgress: Bool

    @State private var isLogoSettled = false

    private var theme: Theme {
        themeManager.theme(for: colorScheme)
    }

    var body: some View {
        ZStack {
            theme.colors.background.ignoresSafeArea()

            VStack(spacing: theme.spacing.xl) {
                VStack(spacing: theme.spacing.l) {
                    Image("EntryLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: theme.spacing.xxl * 4,
                            height: theme.spacing.xxl * 4
                        )
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.sheet, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: theme.radii.sheet, style: .continuous)
                                .stroke(theme.colors.border, lineWidth: 1)
                        }
                        .scaleEffect(reduceMotion || isLogoSettled ? 1 : 0.96)
                        .accessibilityHidden(true)

                    VStack(spacing: theme.spacing.s) {
                        Text("HABITS")
                            .font(theme.typography.title.weight(.bold))
                            .tracking(theme.spacing.xs)
                            .foregroundStyle(theme.colors.textPrimary)

                        Text("Small rhythms. A fuller life.")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("HabitsTracker. Small rhythms. A fuller life.")
                }

                progressRegion
            }
            .padding(theme.spacing.xl)
        }
        .onAppear {
            guard !reduceMotion else {
                isLogoSettled = true
                return
            }

            withAnimation(theme.motion.ease) {
                isLogoSettled = true
            }
        }
    }

    private var progressRegion: some View {
        Group {
            if showsProgress {
                VStack(spacing: theme.spacing.s) {
                    ProgressView()
                        .tint(theme.colors.accentPrimary)
                    Text("Preparing your day…")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .transition(.opacity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Preparing your day")
            }
        }
        .frame(minHeight: theme.spacing.xxl * 2)
        .animation(reduceMotion ? nil : theme.motion.ease, value: showsProgress)
    }
}
