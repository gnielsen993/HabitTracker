import SwiftUI
import DesignKit

/// A data-driven row displaying one `Rule` inside the Rules section of `DomainDetailView`.
/// Owns no `@Query` or `modelContext` — the parent provides a `Rule` value (§9.2).
///
/// Visual: `DKCard` surface; headline title (1–2 lines); optional caption line showing
/// "Stemmed: {N}" when stem count > 0 and/or "· has link" when sourceURL is present.
/// The entire row is a ≥44pt tap target.
struct RuleRow: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let rule: Rule

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(rule.title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                if let secondary = secondaryLine {
                    Text(secondary)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Helpers

    /// Composes the optional second line from stemmed count and/or link indicator.
    /// Returns nil when neither applies (omits the line entirely per S1 contract).
    private var secondaryLine: String? {
        let stemCount = rule.stemmedHabits.count
        let hasLink = rule.sourceURL != nil

        guard stemCount > 0 || hasLink else { return nil }

        var parts: [String] = []
        if stemCount > 0 { parts.append("Inspired: \(stemCount)") }
        if hasLink { parts.append("· has link") }
        return parts.joined(separator: " ")
    }

    private var accessibilityLabel: String {
        var label = "\(rule.title), principle"
        let stemCount = rule.stemmedHabits.count
        if stemCount > 0 { label += ", inspired \(stemCount) habit\(stemCount == 1 ? "" : "s")" }
        if rule.sourceURL != nil { label += ", has link" }
        return label
    }
}
