import SwiftUI
import SwiftData
import DesignKit

/// The Hub inbox (S4, IDEA-03, D-03/D-04/D-05): a data-driven list of unfiled ideas.
///
/// Owns its own `@Query` (D-05, unlike `DomainDetailView` which takes `domain: Domain`
/// as a prop) — the query, not a passed-in array, is the single source of truth for
/// "what's still unfiled". Pushed from `HubView`'s inbox card via a plain
/// `NavigationLink`, so this view declares NO `NavigationStack` of its own; it nests
/// under HubView's stack (matches `DomainDetailView`'s precedent of not owning a
/// second nav container).
struct InboxView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(
        filter: #Predicate<Idea> { $0.domain == nil && !$0.isArchived },
        sort: \Idea.createdAt,
        order: .reverse
    )
    private var unfiledIdeas: [Idea]

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                if unfiledIdeas.isEmpty {
                    emptyState(theme: theme)
                } else {
                    ForEach(unfiledIdeas) { idea in
                        IdeaRow(idea: idea)
                    }
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationTitle("Inbox")
    }

    // MARK: - Empty state

    /// Minimal D-04 placeholder — NOT the Phase 6 designed empty state (flag: POL-02
    /// replaces this with a fuller treatment). Single centered line, no heading, no CTA.
    private func emptyState(theme: Theme) -> some View {
        Text("Nothing to file right now.")
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.top, theme.spacing.xxl)
    }
}
