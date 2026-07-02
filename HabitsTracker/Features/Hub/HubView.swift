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
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(filter: #Predicate<Domain> { $0.isFocused }, sort: \Domain.sortIndex)
    private var focusedDomains: [Domain]

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Group {
                if focusedDomains.isEmpty {
                    emptyState(theme: theme)
                } else {
                    grid(theme: theme)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Hub")
            .navigationDestination(for: Domain.self) { domain in
                DomainDetailView(domain: domain)
            }
        }
    }

    private func grid(theme: Theme) -> some View {
        ScrollView {
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
            .padding(theme.spacing.l)
        }
    }

    private func emptyState(theme: Theme) -> some View {
        VStack(spacing: theme.spacing.l) {
            Text("Your Hub is empty")
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Focus a domain to pin it here. Open the focus picker to choose what belongs in your Hub.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                DomainFocusPicker()
            } label: {
                Text("Choose Domains")
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
