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
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let domain: Domain

    @State private var creatingRule = false
    @State private var creatingHabit = false
    @State private var creatingCollection = false
    @State private var creatingClip = false
    @State private var creatingIdea = false

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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Habit") { creatingHabit = true }
                    Button("Principle") { creatingRule = true }
                    Button("List") { creatingCollection = true }
                    Button("Saved Link") { creatingClip = true }
                    Button("Thought") { creatingIdea = true }
                } label: {
                    Label("Create in \(domain.name)", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $creatingHabit) {
            HabitCreateSheet(source: .manual(domain))
        }
        .sheet(isPresented: $creatingRule) {
            RuleEditorView(domain: domain)
        }
        .sheet(isPresented: $creatingCollection) {
            CollectionPresetPickerSheet(domain: domain)
        }
        .sheet(isPresented: $creatingClip) {
            ClipEditorView(domain: domain)
        }
        .sheet(isPresented: $creatingIdea) {
            IdeaCaptureSheet(domain: domain)
        }
    }

    // MARK: - Sections

    /// Builds the domain's offshoot sections, keeping ONLY the non-empty ones (DOM-03).
    /// Phase 1 had no offshoot item types; Phase B appends the Rules section here.
    /// Phases C–E will append Collections / Clips / Ideas sections in the same pattern.
    private func nonEmptySections(theme: Theme) -> [DomainSection] {
        var sections: [DomainSection] = []

        // Phase B: Rules section (RULE-01) — only when the domain has non-archived rules.
        if let rulesSection = buildRulesSection(theme: theme) {
            sections.append(rulesSection)
        }

        // Phase C: Collections section (COLL-01, D-15)
        if let collectionsSection = buildCollectionsSection(theme: theme) {
            sections.append(collectionsSection)
        }

        // Phase D: Clips section (CLIP-03, D-10)
        if let clipsSection = buildClipsSection(theme: theme) {
            sections.append(clipsSection)
        }

        // Phase E: Ideas section (IDEA-01, IDEA-03, D-08, D-09)
        if let ideasSection = buildIdeasSection(theme: theme) {
            sections.append(ideasSection)
        }

        return sections
    }

    /// Builds the Rules section for this domain, or returns nil when there are no
    /// non-archived rules (preserving the DOM-03 "only non-empty sections" contract).
    private func buildRulesSection(theme: Theme) -> DomainSection? {
        let activeRules = domain.rules
            .filter { !$0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }

        guard !activeRules.isEmpty else { return nil }

        let content = AnyView(rulesSectionContent(rules: activeRules, theme: theme))
        return DomainSection(id: "rules", title: "Principles", content: content)
    }

    // MARK: - Rules section content

    @ViewBuilder
    private func rulesSectionContent(rules: [Rule], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            rulesSectionHeader(theme: theme)

            ForEach(rules, id: \.id) { rule in
                NavigationLink {
                    RuleDetailView(rule: rule)
                } label: {
                    RuleRow(rule: rule)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// A section header row: "Rules" title on the left + "+" add button on the right.
    private func rulesSectionHeader(theme: Theme) -> some View {
        HStack(alignment: .center) {
            Text("Principles")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                creatingRule = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.accentPrimary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Add principle to \(domain.name)")
        }
    }

    // MARK: - Collections section content

    /// Builds the Collections section for this domain, or returns nil when there are no
    /// collections (preserving the DOM-03 "only non-empty sections" contract, D-15).
    private func buildCollectionsSection(theme: Theme) -> DomainSection? {
        let sorted = domain.collections.sorted { $0.sortIndex < $1.sortIndex }
        guard !domain.collections.isEmpty else { return nil }

        let content = AnyView(collectionsSectionContent(collections: sorted, theme: theme))
        return DomainSection(id: "collections", title: "Lists", content: content)
    }

    @ViewBuilder
    private func collectionsSectionContent(collections: [Collection], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            collectionsSectionHeader(theme: theme)

            ForEach(collections, id: \.id) { collection in
                NavigationLink {
                    CollectionDetailView(collection: collection)
                } label: {
                    CollectionRow(collection: collection)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// A section header row: "Collections" title on the left + "+" add button on the right.
    private func collectionsSectionHeader(theme: Theme) -> some View {
        HStack(alignment: .center) {
            Text("Lists")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                creatingCollection = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.accentPrimary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Add list to \(domain.name)")
        }
    }

    // MARK: - Clips section content

    /// Builds the Clips section for this domain, or returns nil when there are no
    /// non-archived clips (preserving the DOM-03 "only non-empty sections" contract, D-10).
    private func buildClipsSection(theme: Theme) -> DomainSection? {
        let activeClips = domain.clips
            .filter { !$0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }

        guard !activeClips.isEmpty else { return nil }

        let content = AnyView(clipsSectionContent(clips: activeClips, theme: theme))
        return DomainSection(id: "clips", title: "Saved Links", content: content)
    }

    @ViewBuilder
    private func clipsSectionContent(clips: [Clip], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            clipsSectionHeader(theme: theme)

            ForEach(clips, id: \.id) { clip in
                NavigationLink {
                    ClipDetailView(clip: clip)
                } label: {
                    ClipRow(clip: clip)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// A section header row: "Clips" title on the left + "+" add button on the right.
    private func clipsSectionHeader(theme: Theme) -> some View {
        HStack(alignment: .center) {
            Text("Saved Links")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                creatingClip = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.accentPrimary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Add saved link to \(domain.name)")
        }
    }

    // MARK: - Ideas section content

    /// Builds the Ideas section for this domain, or returns nil when there are no
    /// non-archived filed ideas (preserving the DOM-03 "only non-empty sections"
    /// contract, D-09). Filed ideas are those with `domain != nil` — unfiled ideas
    /// live in the Hub inbox (05-08), not here.
    private func buildIdeasSection(theme: Theme) -> DomainSection? {
        let activeIdeas = domain.ideas
            .filter { !$0.isArchived }
            .sorted { $0.createdAt > $1.createdAt }

        guard !activeIdeas.isEmpty else { return nil }

        let content = AnyView(ideasSectionContent(ideas: activeIdeas, theme: theme))
        return DomainSection(id: "ideas", title: "Thoughts", content: content)
    }

    /// Renders each idea via `IdeaRow` directly — deliberately NO `NavigationLink`/
    /// detail-view wrapper here (D-08 deviation from the Rules/Collections/Clips
    /// trio shape): `IdeaRow` owns its own tap-to-edit affordance internally.
    @ViewBuilder
    private func ideasSectionContent(ideas: [Idea], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            ideasSectionHeader(theme: theme)

            ForEach(ideas, id: \.id) { idea in
                IdeaRow(idea: idea)
            }
        }
    }

    /// A section header row: "Ideas" title on the left + "+" add button on the right.
    /// The "+" presents `IdeaCaptureSheet(domain:)` pre-filed under this domain
    /// (place-first, D-09) — no domain picker.
    private func ideasSectionHeader(theme: Theme) -> some View {
        HStack(alignment: .center) {
            Text("Thoughts")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                creatingIdea = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.colors.accentPrimary)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Add thought to \(domain.name)")
        }
    }

    // MARK: - Header + empty state

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
        .accessibilityLabel("\(domain.name), area")
    }

    private func emptyState(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Nothing here yet")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Habits, principles, lists, saved links, and thoughts in this area will show up here.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.m)
    }
}
