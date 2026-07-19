import SwiftUI
import DesignKit

struct OnboardingWelcomePage: View {
    let theme: Theme

    var body: some View {
        OnboardingPageShell(
            eyebrow: "A QUIET PLACE FOR WHAT MATTERS",
            title: "Build a life that feels like yours.",
            message: "Habits, ideas, principles, lists, and progress — held together without noise.",
            theme: theme
        ) {
            ZStack {
                Circle()
                    .fill(theme.colors.highlight)
                    .frame(width: theme.spacing.xxl * 5, height: theme.spacing.xxl * 5)

                VStack(spacing: theme.spacing.s) {
                    Image(systemName: "leaf.fill")
                        .font(theme.typography.titleLarge)
                        .foregroundStyle(theme.colors.accentPrimary)
                    Text("YOUR LIFE")
                        .font(theme.typography.caption.weight(.bold))
                        .foregroundStyle(theme.colors.textSecondary)
                }

                orbitLabel("TODAY", icon: "sun.max.fill")
                    .offset(x: -theme.spacing.xxl * 2, y: -theme.spacing.xxl * 2)
                orbitLabel("MY LIFE", icon: "square.grid.2x2.fill")
                    .offset(x: theme.spacing.xxl * 2, y: -theme.spacing.xl)
                orbitLabel("PROGRESS", icon: "chart.line.uptrend.xyaxis")
                    .offset(x: theme.spacing.xl, y: theme.spacing.xxl * 2)
            }
            .frame(maxWidth: .infinity, minHeight: theme.spacing.xxl * 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Today, My Life, and Progress connected around your life")
        }
    }

    private func orbitLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(theme.typography.caption.weight(.semibold))
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.horizontal, theme.spacing.m)
            .padding(.vertical, theme.spacing.s)
            .background(theme.colors.surfaceElevated)
            .clipShape(Capsule())
            .overlay { Capsule().stroke(theme.colors.border, lineWidth: 1) }
    }
}

struct OnboardingHabitPage: View {
    @Binding var isCompleted: Bool
    let theme: Theme
    let reduceMotion: Bool

    var body: some View {
        OnboardingPageShell(
            eyebrow: "TRY IT",
            title: "Start with what’s next.",
            message: "A clear day gets lighter one small action at a time. Tap the habit to feel the rhythm.",
            theme: theme
        ) {
            DKCard(theme: theme) {
                VStack(alignment: .leading, spacing: theme.spacing.l) {
                    HStack {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(isCompleted ? "A MOMENT OF PROGRESS" : "UP NEXT")
                                .font(theme.typography.caption.weight(.bold))
                                .foregroundStyle(theme.colors.accentPrimary)
                            Text(isCompleted ? "You showed up." : "Read for 10 minutes")
                                .font(theme.typography.title)
                                .foregroundStyle(theme.colors.textPrimary)
                        }
                        Spacer()
                        Image(systemName: isCompleted ? "checkmark.seal.fill" : "book.closed.fill")
                            .font(theme.typography.titleLarge)
                            .foregroundStyle(isCompleted ? theme.colors.success : theme.colors.accentSecondary)
                            .contentTransition(.symbolEffect(.replace))
                    }

                    HStack(spacing: theme.spacing.s) {
                        ForEach(0..<7, id: \.self) { day in
                            Image(systemName: day < 4 || (day == 6 && isCompleted) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(day < 4 || (day == 6 && isCompleted) ? theme.colors.success : theme.colors.textTertiary)
                        }
                    }
                    .accessibilityHidden(true)

                    Button {
                        if reduceMotion {
                            isCompleted.toggle()
                        } else {
                            withAnimation(theme.motion.ease) { isCompleted.toggle() }
                        }
                    } label: {
                        Label(isCompleted ? "Completed" : "Mark complete", systemImage: isCompleted ? "checkmark" : "circle")
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.surfaceElevated)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.vertical, theme.spacing.s)
                            .background(isCompleted ? theme.colors.success : theme.colors.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.button, style: .continuous))
                    }
                    .sensoryFeedback(.success, trigger: isCompleted)
                    .accessibilityHint("This is a demonstration and does not change your habit history")
                }
            }
        }
    }
}

struct OnboardingLifePage: View {
    let theme: Theme

    private let features = [
        ("Principles", "What guides you", "quote.opening"),
        ("Lists", "What you're building", "list.bullet.rectangle"),
        ("Saved Links", "What you want nearby", "bookmark"),
        ("Thoughts", "Capture now, sort later", "lightbulb")
    ]

    var body: some View {
        OnboardingPageShell(
            eyebrow: "MORE THAN A TRACKER",
            title: "Keep the whole picture.",
            message: "My Life gives every area a home, so useful things stay connected to why they matter.",
            theme: theme
        ) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: theme.spacing.m), GridItem(.flexible(), spacing: theme.spacing.m)],
                spacing: theme.spacing.m
            ) {
                ForEach(features, id: \.0) { feature in
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        Image(systemName: feature.2)
                            .font(theme.typography.title)
                            .foregroundStyle(theme.colors.accentPrimary)
                        Spacer(minLength: theme.spacing.s)
                        Text(feature.0)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.colors.textPrimary)
                        Text(feature.1)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: theme.spacing.xxl * 3, alignment: .leading)
                    .padding(theme.spacing.l)
                    .background(theme.colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
                            .stroke(theme.colors.border, lineWidth: 1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

struct OnboardingAreasPage: View {
    let domains: [Domain]
    @Binding var selectedDomainIDs: Set<UUID>
    let theme: Theme
    let colorScheme: ColorScheme

    var body: some View {
        OnboardingPageShell(
            eyebrow: "MAKE IT YOURS",
            title: "What matters right now?",
            message: "Choose a few areas to keep close. Everything else stays available whenever life changes.",
            theme: theme
        ) {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: theme.spacing.xxl * 3), spacing: theme.spacing.s)],
                    spacing: theme.spacing.s
                ) {
                    ForEach(domains) { domain in
                        let isSelected = selectedDomainIDs.contains(domain.id)
                        Button { toggle(domain.id) } label: {
                            VStack(spacing: theme.spacing.s) {
                                Image(systemName: domain.iconName)
                                    .font(theme.typography.title)
                                    .foregroundStyle(HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme))
                                Text(domain.name)
                                    .font(theme.typography.caption.weight(.semibold))
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, minHeight: theme.spacing.xxl * 2)
                            .padding(theme.spacing.s)
                            .background(isSelected ? theme.colors.fillSelected : theme.colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
                                    .stroke(isSelected ? theme.colors.accentPrimary : theme.colors.border, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(domain.name), \(isSelected ? "selected" : "not selected")")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
            }
            .frame(maxHeight: theme.spacing.xxl * 8)
        }
    }

    private func toggle(_ id: UUID) {
        if selectedDomainIDs.contains(id) {
            selectedDomainIDs.remove(id)
        } else {
            selectedDomainIDs.insert(id)
        }
    }
}

private struct OnboardingPageShell<Content: View>: View {
    let eyebrow: String
    let title: String
    let message: String
    let theme: Theme
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    Text(eyebrow)
                        .font(theme.typography.caption.weight(.bold))
                        .foregroundStyle(theme.colors.accentPrimary)
                    Text(title)
                        .font(theme.typography.titleLarge)
                        .foregroundStyle(theme.colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(message)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)

                content
            }
            .padding(.horizontal, theme.spacing.l)
            .padding(.vertical, theme.spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
