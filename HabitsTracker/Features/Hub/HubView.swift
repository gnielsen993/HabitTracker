import SwiftUI
import SwiftData
import DesignKit

/// The Hub tab (DOM-03): a grid of the user's focused domains as icon+color tiles.
///
/// The parent owns the `@Query` (§9.2) filtered on `isFocused == true`; `DomainTile`
/// is data-driven. Tapping a tile pushes `DomainDetailView` onto this stack. When no
/// domains are focused, the designed empty state (§9.3, UI-SPEC copy) offers a link
/// into the focus picker so the Hub is never a dead end.
struct HubView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(filter: #Predicate<Domain> { $0.isFocused }, sort: \Domain.sortIndex)
    private var focusedDomains: [Domain]

    @Query(filter: #Predicate<Idea> { $0.domain == nil && !$0.isArchived })
    private var unfiledIdeas: [Idea]

    /// Cross-domain search (POL-01, D-01/D-02): backs `.searchable` on this stack.
    /// A non-empty (trimmed) query swaps the Group's content for `SearchResultsView`.
    @State private var searchText = ""
    @State private var creation: LifeCreation?

    private enum LifeCreation: Identifiable {
        case habit(Domain?), principle(Domain), list(Domain), savedLink(Domain), thought(Domain?)
        var id: String {
            switch self {
            case .habit(let area): "habit-\(area?.id.uuidString ?? "none")"
            case .principle(let area): "principle-\(area.id)"
            case .list(let area): "list-\(area.id)"
            case .savedLink(let area): "link-\(area.id)"
            case .thought(let area): "thought-\(area?.id.uuidString ?? "none")"
            }
        }
    }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        NavigationStack {
            Group {
                if !trimmedSearch.isEmpty {
                    SearchResultsView(query: searchText)
                } else if focusedDomains.isEmpty {
                    emptyState(theme: theme)
                } else {
                    grid(theme: theme)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("My Life")
            .navigationDestination(for: Domain.self) { domain in
                DomainDetailView(domain: domain)
            }
            .searchable(text: $searchText)
            .searchToolbarBehavior(.minimize)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Habit") { creation = .habit(nil) }
                        areaMenu("Principle") { .principle($0) }
                        areaMenu("List") { .list($0) }
                        areaMenu("Saved Link") { .savedLink($0) }
                        Button("Thought") { creation = .thought(nil) }
                    } label: {
                        Label("Create", systemImage: "plus")
                    }
                    .accessibilityLabel("Create in My Life")
                }
            }
            .sheet(item: $creation) { item in
                switch item {
                case .habit(let area): HabitCreateSheet(source: .manual(area))
                case .principle(let area): RuleEditorView(domain: area)
                case .list(let area): CollectionPresetPickerSheet(domain: area)
                case .savedLink(let area): ClipEditorView(domain: area)
                case .thought(let area): IdeaCaptureSheet(domain: area)
                }
            }
        }
    }

    private func areaMenu(
        _ title: String,
        route: @escaping (Domain) -> LifeCreation
    ) -> some View {
        Menu(title) {
            ForEach(focusedDomains) { area in
                Button(area.name) { creation = route(area) }
            }
        }
    }

    private func grid(theme: Theme) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.l) {
                if !unfiledIdeas.isEmpty {
                    inboxCard(theme: theme)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 120), spacing: theme.spacing.m)],
                    spacing: theme.spacing.m
                ) {
                    ForEach(focusedDomains) { domain in
                        NavigationLink(value: domain) {
                            DomainTile(
                                name: domain.name,
                                iconName: domain.iconName,
                                colorToken: domain.colorToken,
                                theme: theme,
                                scheme: colorScheme
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(theme.spacing.l)
        }
    }

    /// The Hub inbox card (S3, IDEA-03, D-03/D-04): pinned above the domain grid,
    /// inside the same ScrollView/VStack — not a separate screen region. Shown only
    /// when unfiled (domain == nil, !isArchived) ideas exist; the card's presence is
    /// itself the signal, so it is entirely absent when the inbox is empty.
    private func inboxCard(theme: Theme) -> some View {
        NavigationLink {
            InboxView()
        } label: {
            DKCard(theme: theme) {
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: "tray.full")
                        .foregroundStyle(theme.colors.accentPrimary)

                    Text("Thoughts without an area")
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    DKBadge("\(unfiledIdeas.count)", theme: theme)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(theme.colors.textTertiary)
                }
                .frame(minHeight: 44)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(unfiledIdeas.count) thoughts without an area")
    }

    private func emptyState(theme: Theme) -> some View {
        VStack(spacing: theme.spacing.l) {
            Text("Make My Life yours")
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Choose the areas you want close at hand, then add habits, principles, lists, links, or thoughts as life unfolds.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                DomainFocusPicker()
            } label: {
                Text("Choose Areas")
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.surfaceElevated)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, theme.spacing.s)
                    .background(theme.colors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.button, style: .continuous))
            }
        }
        .padding(theme.spacing.xl)
    }
}
