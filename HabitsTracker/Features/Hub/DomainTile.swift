import SwiftUI
import DesignKit

/// A data-driven Hub tile (§9.2): props only, runs no SwiftData query. The parent
/// (`HubView`) owns the query and passes each focused domain's fields in.
///
/// The tile carries its domain's accent identity: the centered SF Symbol is tinted
/// via `accentColor(forToken:scheme:)` (the single place a stored `colorToken`
/// becomes a `Color`). Accent is reserved here for the glyph only (UI-SPEC §Color);
/// all other chrome uses `theme.colors.*` so one color stays one domain identity.
struct DomainTile: View {
    let name: String
    let iconName: String
    let colorToken: String
    let theme: Theme
    let scheme: ColorScheme

    var body: some View {
        DKCard(theme: theme) {
            VStack(spacing: theme.spacing.xs) {
                Image(systemName: iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(HabitsTracker.accentColor(forToken: colorToken, scheme: scheme))

                Text(name)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), area")
    }
}
