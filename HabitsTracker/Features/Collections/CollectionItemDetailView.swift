import SwiftUI
import DesignKit

/// The read + position-control surface for a `CollectionItem` (S5, COLL-03 / COLL-04 / COLL-05).
///
/// Data-driven: takes a `CollectionItem` value; declares no nav container of its own — nests under
/// Hub's stack. The toolbar "Edit" button presents `CollectionItemEditorSheet` in edit mode.
///
/// Block ordering per 03-UI-SPEC S5:
///   1. Status (always) — tap-to-advance DKBadge chip (D-06/D-07/D-08)
///   2. Position controls (when progressTemplate != "none") — read-only display + buttons (D-09/D-10)
///   3. Metadata (each omitted when nil/empty) — note, URL, cost
struct CollectionItemDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    let item: CollectionItem

    @State private var editingItem = false
    @State private var chipTapCounter: Int = 0

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                statusBlock(theme: theme)

                if let template = item.collection?.progressTemplate, template != "none" {
                    positionBlock(template: template, theme: theme)
                }

                metadataBlocks(theme: theme)
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    editingItem = true
                }
                .foregroundStyle(theme.colors.accentPrimary)
            }
        }
        .sheet(isPresented: $editingItem) {
            CollectionItemEditorSheet(item: item)
        }
    }

    // MARK: - Block 1: Status

    private func statusBlock(theme: Theme) -> some View {
        let statusSet = item.collection.flatMap { StatusSetCatalog.set(for: $0.statusSetID) }
        let terminalIndex = statusSet?.terminalIndex ?? 0
        let statusLabel = statusSet?.states[safe: item.statusIndex] ?? ""

        return VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Status")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)

            DKBadge(statusLabel, theme: theme)
                .frame(minWidth: 44, minHeight: 44)
                .onTapGesture {
                    chipTapCounter += 1
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
                .sensoryFeedback(.impact(weight: .light), trigger: chipTapCounter)
                .accessibilityLabel("Status: \(statusLabel), \(item.title)")
                .accessibilityAction(named: "Reset status") {
                    item.statusIndex = 0
                }
        }
    }

    // MARK: - Block 2: Position controls (conditional)

    @ViewBuilder
    private func positionBlock(template: String, theme: Theme) -> some View {
        let statusSet = item.collection.flatMap { StatusSetCatalog.set(for: $0.statusSetID) }
        let terminalIndex = statusSet?.terminalIndex ?? 0
        let atTerminal = item.statusIndex >= terminalIndex

        VStack(alignment: .leading, spacing: theme.spacing.m) {
            // Read-only position display
            Text(positionDisplayText(template: template))
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityLabel(positionAccessibilityLabel(template: template))

            // Position control buttons
            if template == "seasonEpisode" {
                HStack(spacing: theme.spacing.m) {
                    positionButton(label: "+Episode", a11yLabel: "Next episode", theme: theme) {
                        item.episode += 1
                    }
                    positionButton(label: "+Season", a11yLabel: "Next season", theme: theme) {
                        item.season += 1
                        item.episode = 1
                    }
                    if !atTerminal {
                        positionButton(label: "Finished", a11yLabel: "Mark as finished", theme: theme) {
                            item.statusIndex = terminalIndex
                        }
                    }
                }
            } else if template == "counter" {
                let counterLabel = item.counterLabel ?? "Item"
                positionButton(
                    label: "+\(counterLabel)",
                    a11yLabel: "Add one \(counterLabel)",
                    theme: theme
                ) {
                    item.counterValue += 1
                }
            }
        }
    }

    private func positionDisplayText(template: String) -> String {
        if template == "seasonEpisode" {
            return "S\(item.season) E\(item.episode)"
        } else {
            let label = item.counterLabel ?? "Item"
            return "\(label) \(item.counterValue)"
        }
    }

    private func positionAccessibilityLabel(template: String) -> String {
        if template == "seasonEpisode" {
            return "Current position: S\(item.season) E\(item.episode)"
        } else {
            let label = item.counterLabel ?? "Item"
            return "Current \(label): \(item.counterValue)"
        }
    }

    private func positionButton(
        label: String,
        a11yLabel: String,
        theme: Theme,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Text(label)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.accentPrimary)
                .padding(.horizontal, theme.spacing.m)
                .padding(.vertical, theme.spacing.s)
                .frame(minWidth: 44, minHeight: 44)
                .background(theme.colors.surface)
                .cornerRadius(theme.radii.button)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.button)
                        .stroke(theme.colors.border, lineWidth: 1)
                )
        }
        .accessibilityLabel(a11yLabel)
    }

    // MARK: - Block 3: Metadata (each omitted when empty/nil)

    @ViewBuilder
    private func metadataBlocks(theme: Theme) -> some View {
        // Note
        if let note = item.note, !note.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Note")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                Text(note)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        // URL / Source (reuses RuleDetailView bordered Link block pattern)
        if let urlString = item.sourceURL,
           let url = URL(string: urlString) {
            let host = url.host ?? urlString
            Link(destination: url) {
                HStack(spacing: theme.spacing.s) {
                    Image(systemName: "link")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(host)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.textPrimary)
                        Text(urlString)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(theme.spacing.m)
                .background(theme.colors.surface)
                .cornerRadius(theme.radii.card)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.card)
                        .stroke(theme.colors.border, lineWidth: 1)
                )
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Open link, \(host)")
        }

        // Cost
        if let cost = item.cost {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("Cost")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                Text(formattedCost(cost))
                    .font(theme.typography.monoNumber)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
    }

    // MARK: - Helpers

    private func formattedCost(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = .current
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "$\(formatted)"
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
