import SwiftUI
import SwiftData
import DesignKit

/// App-wide Collection picker for promote-to-collection (S7, IDEA-05).
///
/// No exact analog exists in the repo (no prior "pick one of N app-wide items across
/// domains" screen) — composes `DomainFocusPicker`'s row-list shape with
/// `RuleEditorView`'s toolbar Cancel. Lists every `Collection` regardless of domain;
/// tapping a row dismisses this picker and opens `CollectionItemEditorSheet` prefilled
/// from the idea. Picking the collection IS the domain selection (no extra domain
/// gate needed, unlike the Rule promote path).
struct PromoteToCollectionPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Collection.title) private var collections: [Collection]

    let idea: Idea

    @State private var pickedCollection: Collection?

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Group {
                if collections.isEmpty {
                    emptyState(theme: theme)
                } else {
                    list(theme: theme)
                }
            }
            .background(theme.colors.background)
            .navigationTitle("Choose a List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $pickedCollection) { collection in
                CollectionItemEditorSheet(collection: collection, promotingIdea: idea)
                    .onDisappear {
                        // A successful promote-Save consumes the idea (archived); close
                        // the picker so a second pick can't create a duplicate item
                        // (WR-02). On Cancel the idea is untouched, so the picker stays
                        // open for another choice.
                        if idea.isArchived { dismiss() }
                    }
            }
        }
    }

    private func list(theme: Theme) -> some View {
        ScrollView {
            VStack(spacing: theme.spacing.m) {
                ForEach(collections) { collection in
                    Button {
                        pickedCollection = collection
                    } label: {
                        row(for: collection, theme: theme)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(theme.spacing.l)
        }
    }

    private func row(for collection: Collection, theme: Theme) -> some View {
        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(collection.title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)

                if let domainName = collection.domain?.name {
                    Text(domainName)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: collection))
    }

    private func accessibilityLabel(for collection: Collection) -> String {
        guard let domainName = collection.domain?.name else { return collection.title }
        return "\(collection.title), \(domainName)"
    }

    private func emptyState(theme: Theme) -> some View {
        Text("No lists yet. Create a list in an area first.")
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(theme.spacing.xl)
    }
}
