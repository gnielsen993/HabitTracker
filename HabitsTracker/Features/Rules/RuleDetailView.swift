import SwiftUI
import DesignKit

/// The reference-first read surface for a `Rule` (S2, RULE-01/RULE-03/RULE-04).
///
/// Data-driven: takes a `Rule` value; declares NO `NavigationStack` of its own —
/// it nests under HubView's stack (mirrors `DomainDetailView`). The toolbar's "Edit"
/// button presents `RuleEditorView` as a sheet.
///
/// Block ordering per 02-UI-SPEC S2:
///   1. Header — domain glyph (accent-tinted) + rule title + optional "Archived" badge
///   2. Body  — rule body text (omitted when empty)
///   3. Source — bordered URL affordance (omitted when sourceURL is nil)
///   4. Stem  — "Stem habit" primary CTA (presents HabitCreateSheet — RULE-03)
///   5. Stemmed — "Stemmed habits" section (omitted when no stemmed habits)
struct RuleDetailView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    let rule: Rule

    @State private var editingRule = false
    @State private var stemming = false       // 02-03 wires the real sheet here
    @State private var editingHabit: Habit?  // sheet for stemmed-habit rows

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                headerBlock(theme: theme)

                if !rule.body.isEmpty {
                    bodyBlock(theme: theme)
                }

                if rule.sourceURL != nil {
                    sourceBlock(theme: theme)
                }

                stemButton(theme: theme)

                if !rule.stemmedHabits.isEmpty {
                    stemmedBlock(theme: theme)
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    editingRule = true
                }
                .foregroundStyle(theme.colors.accentPrimary)
            }
        }
        .sheet(isPresented: $editingRule) {
            RuleEditorView(rule: rule)
        }
        .sheet(isPresented: $stemming) {
            HabitCreateSheet(source: .rule(rule))
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditorView(habit: habit)
        }
    }

    // MARK: - Block 1: Header

    private func headerBlock(theme: Theme) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.m) {
            if let domain = rule.domain {
                Image(systemName: domain.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme)
                    )
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(rule.title)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)

                if rule.isArchived {
                    DKBadge("Archived", theme: theme)
                        .accessibilityLabel("Archived principle")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        var label = rule.title + ", principle"
        if rule.isArchived { label += ", archived" }
        return label
    }

    // MARK: - Block 2: Body

    private func bodyBlock(theme: Theme) -> some View {
        Text(rule.body)
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textPrimary)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Block 3: Source URL (conditional)

    @ViewBuilder
    private func sourceBlock(theme: Theme) -> some View {
        if let urlString = rule.sourceURL,
           let url = URL(string: urlString) {
            let host = url.host ?? urlString

            Link(destination: url) {
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: "link")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(host)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.textPrimary)

                        Text(urlString)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(theme.spacing.m)
                .background(theme.colors.surface)
                .cornerRadius(theme.radii.card)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.card)
                        .stroke(theme.colors.border, lineWidth: 1)
                )
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Open source link, \(host)")
        }
    }

    // MARK: - Block 4: Stem CTA

    private func stemButton(theme: Theme) -> some View {
        Button {
            stemming = true
        } label: {
            Text("Create Habit")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.background)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(theme.colors.accentPrimary)
                .cornerRadius(theme.radii.button)
        }
        .accessibilityLabel("Create a habit inspired by this principle")
    }

    // MARK: - Block 5: Stemmed habits (conditional)

    private func stemmedBlock(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            HStack(alignment: .center) {
                Text("Inspired habits")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                Spacer()

                DKBadge("Inspired: \(rule.stemmedHabits.count)", theme: theme)
            }

            ForEach(rule.stemmedHabits, id: \.id) { habit in
                Button {
                    editingHabit = habit
                } label: {
                    stemmedHabitRow(habit: habit, theme: theme)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stemmedHabitRow(habit: Habit, theme: Theme) -> some View {
        DKCard(theme: theme) {
            Text(habit.name)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.name), inspired habit")
    }
}
