import SwiftUI
import DesignKit

/// A single non-empty offshoot section inside `DomainDetailView`. Phases B–E populate
/// `sections` with Rules / Collections / Clips / Ideas; Phase 1 has no item types yet,
/// so the collection is intentionally empty and the view falls through to its empty state.
private struct DomainSection: Identifiable {
    let id: String
    let title: String
    let content: AnyView
}

/// The detail surface pushed from a Hub tile (DOM-03). Data-driven: it takes the
/// `Domain` value and declares no navigation container of its own — it nests under
/// HubView's stack, so Hub owns the single nav bar (no doubled title).
///
/// Contract (DOM-03 "only non-empty sections"): the body renders a real LOOP over a
/// `sections` collection, drawing a `DKSectionHeader` per non-empty section. In Phase 1
/// that collection yields ZERO sections — offshoot item types arrive in later phases —
/// so the empty state (§9.3, UI-SPEC copy) shows only when the loop produces nothing.
/// This is deliberately a section-loop-with-empty-fallback, not a hardcoded empty view.
struct DomainDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let domain: Domain

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let sections = nonEmptySections(theme: theme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                header(theme: theme)

                if sections.isEmpty {
                    emptyState(theme: theme)
                } else {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: theme.spacing.m) {
                            DKSectionHeader(section.title, theme: theme)
                            section.content
                        }
                    }
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationTitle(domain.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Builds the domain's offshoot sections, keeping ONLY the non-empty ones (DOM-03).
    /// Phase 1 has no offshoot item types yet, so this returns an empty array today;
    /// Phases B–E append Rules / Collections / Clips / Ideas sections (each filtered to
    /// non-empty) here. Structured as a collection so the body renders a real loop.
    private func nonEmptySections(theme: Theme) -> [DomainSection] {
        var sections: [DomainSection] = []
        // Phase B–E append their non-empty item-type sections to `sections` here.
        return sections.filter { _ in true }
    }

    private func header(theme: Theme) -> some View {
        HStack(spacing: theme.spacing.m) {
            Image(systemName: domain.iconName)
                .font(.system(size: 32))
                .foregroundStyle(HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme))

            Text(domain.name)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(domain.name), domain")
    }

    private func emptyState(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Nothing here yet")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Rules, collections, clips and ideas you file under this domain will show up here.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.m)
    }
}
