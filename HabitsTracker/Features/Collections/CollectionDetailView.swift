import SwiftUI
import DesignKit

/// The read surface for a `Collection` (S3, COLL-01 / COLL-03 / COLL-06).
///
/// Data-driven: takes a `Collection` value; declares no nav container of its own —
/// it nests under HubView's stack so Hub owns the single nav bar (no doubled title).
///
/// Block ordering per 03-UI-SPEC S3:
///   1. Header — domain glyph (accent-tinted) + collection name + rollup + StatusSet sub-label
///   2. Items list — ForEach over sorted items (CollectionItemRow wired in 03-04)
///   3. Empty state — shown when collection.items is empty (§9.3)
///
/// Toolbar: trailing "+" to add an item (CollectionItemEditorSheet wired in 03-04).
struct CollectionDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let collection: Collection

    @State private var addingItem = false

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                headerBlock(theme: theme)
                itemsBlock(theme: theme)
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationTitle(collection.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    addingItem = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.colors.accentPrimary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Add item to \(collection.title)")
            }
        }
        // TODO: Replace EmptyView with CollectionItemEditorSheet(collection:) in 03-04
        .sheet(isPresented: $addingItem) {
            EmptyView()
        }
    }

    // MARK: - Header block

    private func headerBlock(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Row 1: domain glyph + collection name
            HStack(alignment: .top, spacing: theme.spacing.m) {
                if let domain = collection.domain {
                    Image(systemName: domain.iconName)
                        .font(.system(size: 28))
                        .foregroundStyle(
                            HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme)
                        )
                        .accessibilityHidden(true)
                }

                Text(collection.title)
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            // Row 2: rollup display (conditional on showsAggregate)
            if collection.showsAggregate {
                rollupBlock(theme: theme)
            }

            // Row 3: StatusSet sub-label (conditional)
            if let subLabel = statusSetSubLabel {
                Text(subLabel)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }

    // MARK: - Rollup block (D-17, D-18, T-03-05)

    @ViewBuilder
    private func rollupBlock(theme: Theme) -> some View {
        let rollup = CollectionRollupEngine.rollup(collection: collection, items: collection.items)

        switch rollup {
        case .count(let x, let y):
            if y == 0 {
                // T-03-05: guard against divide-by-zero — show "0 items" text, no ring
                Text("0 items")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            } else {
                // Completionist with items: show ring + text fallback
                VStack(alignment: .leading, spacing: theme.spacing.s) {
                    DKProgressRing(
                        progress: Double(x) / Double(y),
                        lineWidth: 6,
                        label: "\(x)/\(y)",
                        theme: theme
                    )
                    .frame(width: 56, height: 56)
                    .accessibilityLabel(ringAccessibilityLabel(x: x, y: y))

                    let terminalLabel = StatusSetCatalog.set(for: collection.statusSetID)
                        .map { $0.states[$0.terminalIndex] } ?? "complete"
                    Text("\(x) of \(y) \(terminalLabel)")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }

        case .costSum(let total):
            // Cost: plain text, never a ring (D-18)
            Text(formattedCost(total))
                .font(theme.typography.monoNumber)
                .foregroundStyle(theme.colors.textPrimary)

        case .none:
            EmptyView()
        }
    }

    // MARK: - Items list / empty state

    @ViewBuilder
    private func itemsBlock(theme: Theme) -> some View {
        if collection.items.isEmpty {
            emptyState(theme: theme)
        } else {
            itemsList(theme: theme)
        }
    }

    private func emptyState(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Nothing in this list yet")
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Tap + to add your first item.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, theme.spacing.m)
    }

    /// Placeholder items list — `CollectionItemRow` + NavigationLink wired in 03-04.
    @ViewBuilder
    private func itemsList(theme: Theme) -> some View {
        let sorted = collection.items.sorted { $0.sortIndex < $1.sortIndex }
        // TODO: Replace with NavigationLink { CollectionItemDetailView(item:) } label: { CollectionItemRow(item:collection:) } in 03-04
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            ForEach(sorted, id: \.id) { item in
                itemPlaceholderRow(item: item, theme: theme)
            }
        }
    }

    /// Lightweight read-only row — replaced by CollectionItemRow in 03-04.
    private func itemPlaceholderRow(item: CollectionItem, theme: Theme) -> some View {
        DKCard(theme: theme) {
            HStack(alignment: .center, spacing: theme.spacing.s) {
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(item.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)

                    if let statusSet = StatusSetCatalog.set(for: collection.statusSetID),
                       item.statusIndex < statusSet.states.count {
                        let statusLabel = statusSet.states[item.statusIndex]
                        Text(statusLabel)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(itemAccessibilityLabel(item: item))
    }

    // MARK: - Helpers

    private var statusSetSubLabel: String? {
        guard let set = StatusSetCatalog.set(for: collection.statusSetID) else { return nil }
        let flow = set.states.joined(separator: " → ")
        return "\(collection.title) — \(flow)"
    }

    private func ringAccessibilityLabel(x: Int, y: Int) -> String {
        let terminalLabel = StatusSetCatalog.set(for: collection.statusSetID)
            .map { $0.states[$0.terminalIndex] } ?? "complete"
        let percent = y > 0 ? Int((Double(x) / Double(y)) * 100) : 0
        return "\(x) of \(y) \(terminalLabel), \(percent) percent complete"
    }

    private func itemAccessibilityLabel(item: CollectionItem) -> String {
        var label = item.title
        if let statusSet = StatusSetCatalog.set(for: collection.statusSetID),
           item.statusIndex < statusSet.states.count {
            label += ", status: \(statusSet.states[item.statusIndex])"
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
