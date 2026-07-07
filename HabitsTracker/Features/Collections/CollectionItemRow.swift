import SwiftUI
import DesignKit

/// A data-driven compact row for a `CollectionItem` inside `CollectionDetailView` (S4).
///
/// Takes `item: CollectionItem` and `collection: Collection` — owns no `@Query` (§9.2).
///
/// Tap-to-advance chip (D-06): advances `statusIndex` by 1, clamped at `terminalIndex`.
/// Sensory feedback fires on every tap including at terminal (D-08) via a dedicated tap counter.
/// contextMenu "Reset" + VoiceOver "Reset status" custom action sets `statusIndex = 0` (D-07).
/// Compact position label shown when `progressTemplate != "none"` (D-09).
struct CollectionItemRow: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let item: CollectionItem
    let collection: Collection

    /// Incremented on every chip tap to trigger sensory feedback even when statusIndex
    /// does not change (terminal tap). See D-08.
    @State private var tapCounter: Int = 0

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let statusSet = StatusSetCatalog.set(for: collection.statusSetID)
        let terminalIndex = statusSet?.terminalIndex ?? 0
        let statusLabel = statusSet?.states[safe: item.statusIndex] ?? ""

        DKCard(theme: theme) {
            HStack(alignment: .center, spacing: theme.spacing.m) {
                // Leading: title + optional compact position label
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(item.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    if let positionLabel = compactPositionLabel {
                        Text(positionLabel)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                Spacer()

                // Trailing: tap-to-advance status chip (D-06, D-07, D-08)
                DKBadge(statusLabel, theme: theme)
                    .frame(minWidth: 44, minHeight: 44)
                    .onTapGesture {
                        tapCounter += 1
                        let newIndex = min(item.statusIndex + 1, terminalIndex)
                        if item.statusIndex != newIndex {
                            item.statusIndex = newIndex
                        }
                    }
                    .contextMenu {
                        Button("Reset", role: .destructive) {
                            item.statusIndex = 0
                        }
                    }
                    // D-08: fire on every tap, including terminal (keyed on tapCounter not statusIndex)
                    .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(statusLabel: statusLabel))
        .accessibilityAction(named: "Reset status") {
            item.statusIndex = 0
        }
    }

    // MARK: - Helpers

    /// "S{season} E{episode}" for seasonEpisode; "{counterLabel} {counterValue}" for counter; nil for none.
    private var compactPositionLabel: String? {
        switch collection.progressTemplate {
        case "seasonEpisode":
            return "S\(item.season) E\(item.episode)"
        case "counter":
            let label = item.counterLabel ?? "Item"
            return "\(label) \(item.counterValue)"
        default:
            return nil
        }
    }

    private func rowAccessibilityLabel(statusLabel: String) -> String {
        var label = "\(item.title), status: \(statusLabel)"
        if let positionLabel = compactPositionLabel {
            label += ", \(positionLabel)"
        }
        return label
    }
}

// MARK: - Array safe subscript

private extension Array {
    /// Returns the element at the given index, or nil if out of bounds.
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
