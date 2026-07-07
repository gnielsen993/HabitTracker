import SwiftUI
import DesignKit

/// A data-driven row displaying one `Collection` inside the Collections section of
/// `DomainDetailView`. Owns no `@Query` or `modelContext` — the parent provides the
/// `Collection` value (§9.2).
///
/// Visual: `DKCard` surface; headline collection title (1 line); StatusSet sub-label
/// (caption) showing the state set name (e.g. "Shows — watched"); trailing rollup
/// label when `showsAggregate == true` ("X/Y" caption or "$NNN" monoNumber).
/// The entire row is a ≥44pt tap target. (§9.15)
struct CollectionRow: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let collection: Collection

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let rollup = CollectionRollupEngine.rollup(collection: collection, items: collection.items)

        DKCard(theme: theme) {
            HStack(alignment: .center, spacing: theme.spacing.s) {
                // Leading: title + StatusSet sub-label
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(collection.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)

                    if let subLabel = statusSetSubLabel {
                        Text(subLabel)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Trailing rollup (conditional on showsAggregate + engine result)
                if collection.showsAggregate {
                    trailingRollup(rollup: rollup, theme: theme)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(rollup: rollup))
    }

    // MARK: - Trailing rollup

    @ViewBuilder
    private func trailingRollup(rollup: CollectionRollupEngine.Result, theme: Theme) -> some View {
        switch rollup {
        case .count(let x, let y) where y > 0:
            Text("\(x)/\(y)")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .monospacedDigit()

        case .costSum(let total):
            Text(formattedCost(total))
                .font(theme.typography.monoNumber)
                .foregroundStyle(theme.colors.textSecondary)

        default:
            // .none, or .count with y == 0 — no trailing label
            EmptyView()
        }
    }

    // MARK: - Helpers

    /// Builds "Shows — watched" sub-label from the StatusSet terminal state label.
    private var statusSetSubLabel: String? {
        guard let set = StatusSetCatalog.set(for: collection.statusSetID) else { return nil }
        let terminalLabel = set.states[set.terminalIndex]
        return "\(collection.title) — \(terminalLabel)"
    }

    private func accessibilityLabel(rollup: CollectionRollupEngine.Result) -> String {
        let itemCount = collection.items.count
        var label = "\(collection.title), \(itemCount) item\(itemCount == 1 ? "" : "s")"

        if collection.showsAggregate {
            switch rollup {
            case .count(let x, let y) where y > 0:
                let terminal = StatusSetCatalog.set(for: collection.statusSetID)
                let stateLabel = terminal.map { $0.states[$0.terminalIndex] } ?? "complete"
                label += ", \(x) of \(y) \(stateLabel)"
            case .costSum(let total):
                label += ", \(formattedCost(total)) total"
            default:
                break
            }
        }
        return label
    }

    private func formattedCost(_ total: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.locale = .current
        let formatted = formatter.string(from: NSNumber(value: total)) ?? String(format: "%.0f", total)
        return "$\(formatted)"
    }
}
