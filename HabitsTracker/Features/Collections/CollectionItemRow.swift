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
///
/// Chip is a VoiceOver-reachable `Button` (not a bare `.onTapGesture`) exposing the
/// current status as `.accessibilityLabel` and the advance outcome as
/// `.accessibilityHint`, mirroring `ClipRow.statusChip` (POL-04 D-10).
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
                // Leading: title + optional compact position label. Combined into a
                // single VoiceOver element so the status-chip Button stays a
                // separate, reachable control (mirrors ClipRow, D-10).
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(titleAccessibilityLabel)

                Spacer(minLength: 0)

                statusChip(theme: theme, statusLabel: statusLabel, terminalIndex: terminalIndex)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }

    // MARK: - Trailing: tap-to-advance status chip (D-06, D-07, D-08, D-10)

    /// A `Button` (not a raw `.onTapGesture`) so VoiceOver exposes the advance as an
    /// activatable control with a label (current status) + hint (advance outcome).
    /// `.buttonStyle(.plain)` keeps the DKBadge visual. Reset stays reachable both via
    /// the long-press `contextMenu` and a named VoiceOver `.accessibilityAction`.
    private func statusChip(theme: Theme, statusLabel: String, terminalIndex: Int) -> some View {
        Button {
            tapCounter += 1
            let newIndex = min(item.statusIndex + 1, terminalIndex)
            if item.statusIndex != newIndex {
                item.statusIndex = newIndex
            }
        } label: {
            DKBadge(statusLabel, theme: theme)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Reset", role: .destructive) {
                item.statusIndex = 0
            }
        }
        // D-08: fire on every tap, including terminal (keyed on tapCounter not statusIndex)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
        .accessibilityLabel("Status: \(statusLabel), \(item.title)")
        // D-08: at the terminal status the tap is a documented no-op — don't claim an advance.
        .accessibilityHint(item.statusIndex < terminalIndex
            ? "Advances to the next status"
            : "Already at the final status")
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

    private var titleAccessibilityLabel: String {
        var label = item.title
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
