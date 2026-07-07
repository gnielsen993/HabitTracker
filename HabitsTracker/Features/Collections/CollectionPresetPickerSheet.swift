import SwiftUI
import SwiftData
import DesignKit

/// Sheet that presents all `CollectionPresetCatalog` presets so the user can pick one
/// and create a `Collection` filed under the given domain (D-13, COLL-07).
///
/// Tap a preset row → creates a Collection from that preset, files it under `domain`,
/// persists, and dismisses. Cancel → no collection created. No empty state needed —
/// the catalog is always fully populated (9 presets, generic first, D-12).
struct CollectionPresetPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let domain: Domain

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            List {
                ForEach(CollectionPresetCatalog.all, id: \.id) { preset in
                    presetRow(preset: preset, theme: theme)
                        .listRowBackground(theme.colors.surface)
                        .listRowInsets(EdgeInsets(
                            top: theme.spacing.s,
                            leading: theme.spacing.l,
                            bottom: theme.spacing.s,
                            trailing: theme.spacing.l
                        ))
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("Choose a type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel, no collection created")
                }
            }
        }
    }

    // MARK: - Preset row

    private func presetRow(preset: CollectionPreset, theme: Theme) -> some View {
        let description = stateFlowDescription(for: preset.statusSetID)

        return Button {
            createCollection(from: preset)
        } label: {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(preset.name)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(description)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(preset.name), \(description)")
    }

    // MARK: - Collection creation

    private func createCollection(from preset: CollectionPreset) {
        let nextSortIndex = (domain.collections.map(\.sortIndex).max() ?? -1) + 1

        let collection = Collection(
            title: preset.name,
            statusSetID: preset.statusSetID,
            progressTemplate: preset.progressTemplate,
            showsAggregate: preset.showsAggregate,
            sortIndex: nextSortIndex
        )
        collection.domain = domain
        modelContext.insert(collection)
        try? modelContext.save()
        dismiss()
    }

    // MARK: - Helpers

    /// Builds the state-flow description string for a given statusSetID,
    /// e.g. "to-watch → watching → watched" from the catalog states.
    private func stateFlowDescription(for statusSetID: String) -> String {
        guard let set = StatusSetCatalog.set(for: statusSetID) else {
            return statusSetID
        }
        return set.states.joined(separator: " → ")
    }
}
