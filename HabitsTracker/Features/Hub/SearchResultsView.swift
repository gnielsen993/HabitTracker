import SwiftUI
import SwiftData
import DesignKit

/// Cross-domain search results (POL-01), pushed as the Hub's content when the
/// `.searchable` field attached to `HubView` holds a non-empty query (D-01/D-02).
///
/// Owns six `@Query`s — one per searchable type (§9.2: the view owns the queries,
/// rows take values). Types with an archived/consumed flag (Habit, Rule, Clip, Idea)
/// exclude those items at the `#Predicate` level (D-06); Collection/CollectionItem
/// have no such flag, so they need none. Matching against `query` (title + free-text fields, D-04) is
/// done in memory via `.localizedStandardContains` since SwiftData has no cross-model
/// full-text search. Results render as one `Section`-style block per non-empty type
/// (D-03), in Habits/Rules/Collections/Clips/Ideas order, each reusing the item's
/// already-wired row + detail/editor destination (D-07/D-08) — no new rows or detail
/// screens are declared here. A non-empty query with zero total matches shows
/// `ContentUnavailableView.search(text:)` (D-12).
struct SearchResultsView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let query: String

    @Query(filter: #Predicate<Habit> { !$0.isArchived }, sort: \Habit.name)
    private var habits: [Habit]

    @Query(filter: #Predicate<Rule> { !$0.isArchived }, sort: \Rule.createdAt, order: .reverse)
    private var rules: [Rule]

    @Query(sort: \Collection.sortIndex)
    private var collections: [Collection]

    @Query(sort: \CollectionItem.sortIndex)
    private var collectionItems: [CollectionItem]

    @Query(filter: #Predicate<Clip> { !$0.isArchived }, sort: \Clip.createdAt, order: .reverse)
    private var clips: [Clip]

    @Query(
        filter: #Predicate<Idea> { !$0.isArchived && $0.promotedToKindRaw == nil },
        sort: \Idea.createdAt,
        order: .reverse
    )
    private var ideas: [Idea]

    /// Habit results open `HabitEditorView` as a sheet, never a jump to Today (D-08).
    @State private var editingHabit: Habit?

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        Group {
            if hasAnyMatch {
                ScrollView {
                    VStack(alignment: .leading, spacing: theme.spacing.xl) {
                        if !habitMatches.isEmpty {
                            habitsSection(theme: theme)
                        }
                        if !ruleMatches.isEmpty {
                            rulesSection(theme: theme)
                        }
                        if !collectionMatches.isEmpty {
                            collectionsSection(theme: theme)
                        }
                        if !clipMatches.isEmpty {
                            clipsSection(theme: theme)
                        }
                        if !ideaMatches.isEmpty {
                            ideasSection(theme: theme)
                        }
                    }
                    .padding(theme.spacing.l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView.search(text: query)
            }
        }
        .sheet(item: $editingHabit) { habit in
            HabitEditorView(habit: habit)
        }
    }

    // MARK: - Habits

    private func habitsSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            sectionHeader("Habits", theme: theme)

            ForEach(habitMatches, id: \.id) { habit in
                Button {
                    editingHabit = habit
                } label: {
                    habitRow(habit: habit, theme: theme)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func habitRow(habit: Habit, theme: Theme) -> some View {
        DKCard(theme: theme) {
            Text(habit.name)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(habit.name), habit")
    }

    // MARK: - Rules

    private func rulesSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            sectionHeader("Principles", theme: theme)

            ForEach(ruleMatches, id: \.id) { rule in
                NavigationLink {
                    RuleDetailView(rule: rule)
                } label: {
                    RuleRow(rule: rule)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Collections (folds CollectionItem hits into their parent collection)

    private func collectionsSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            sectionHeader("Lists", theme: theme)

            ForEach(collectionMatches, id: \.id) { collection in
                NavigationLink {
                    CollectionDetailView(collection: collection)
                } label: {
                    CollectionRow(collection: collection)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Clips

    private func clipsSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            sectionHeader("Saved Links", theme: theme)

            ForEach(clipMatches, id: \.id) { clip in
                NavigationLink {
                    ClipDetailView(clip: clip)
                } label: {
                    ClipRow(clip: clip)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Ideas (IdeaRow already owns its tap -> edit sheet, D-08)

    private func ideasSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            sectionHeader("Thoughts", theme: theme)

            ForEach(ideaMatches, id: \.id) { idea in
                IdeaRow(idea: idea)
            }
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String, theme: Theme) -> some View {
        Text(title)
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Matching (D-04: title + free-text fields via .localizedStandardContains)

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasAnyMatch: Bool {
        !habitMatches.isEmpty || !ruleMatches.isEmpty || !collectionMatches.isEmpty
            || !clipMatches.isEmpty || !ideaMatches.isEmpty
    }

    private var habitMatches: [Habit] {
        guard !trimmedQuery.isEmpty else { return [] }
        return habits.filter { $0.name.localizedStandardContains(trimmedQuery) }
    }

    private var ruleMatches: [Rule] {
        guard !trimmedQuery.isEmpty else { return [] }
        return rules.filter {
            $0.title.localizedStandardContains(trimmedQuery)
                || $0.body.localizedStandardContains(trimmedQuery)
        }
    }

    /// Direct Collection title/note hits, unioned with the parent collections of any
    /// matching CollectionItem (folded up, per plan: item hits surface under Collections).
    private var collectionMatches: [Collection] {
        guard !trimmedQuery.isEmpty else { return [] }

        let directHits = collections.filter {
            $0.title.localizedStandardContains(trimmedQuery)
                || ($0.note?.localizedStandardContains(trimmedQuery) ?? false)
        }

        let itemHitParents = collectionItems
            .filter {
                $0.title.localizedStandardContains(trimmedQuery)
                    || ($0.note?.localizedStandardContains(trimmedQuery) ?? false)
            }
            .compactMap { $0.collection }

        var seen = Set<UUID>()
        var merged: [Collection] = []
        for collection in directHits + itemHitParents where !seen.contains(collection.id) {
            seen.insert(collection.id)
            merged.append(collection)
        }
        return merged.sorted { $0.sortIndex < $1.sortIndex }
    }

    private var clipMatches: [Clip] {
        guard !trimmedQuery.isEmpty else { return [] }
        return clips.filter {
            $0.title.localizedStandardContains(trimmedQuery)
                || $0.url.localizedStandardContains(trimmedQuery)
                || ($0.note?.localizedStandardContains(trimmedQuery) ?? false)
                || ($0.tag?.localizedStandardContains(trimmedQuery) ?? false)
        }
    }

    private var ideaMatches: [Idea] {
        guard !trimmedQuery.isEmpty else { return [] }
        return ideas.filter {
            $0.title.localizedStandardContains(trimmedQuery)
                || ($0.note?.localizedStandardContains(trimmedQuery) ?? false)
                || ($0.url?.localizedStandardContains(trimmedQuery) ?? false)
        }
    }
}
