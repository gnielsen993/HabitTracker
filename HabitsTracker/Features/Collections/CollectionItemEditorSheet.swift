import SwiftUI
import SwiftData
import DesignKit

/// Create / edit sheet for a `CollectionItem` (S6).
///
/// Structural copy of `RuleEditorView`. Two modes:
///   - Create: `CollectionItemEditorSheet(collection:)` — inserts a new item; CTA "Add Item".
///   - Edit:   `CollectionItemEditorSheet(item:)` — mutates in place; CTA "Save Changes".
///
/// Title is required (trimmed non-empty). Note, URL, and Cost are optional.
/// Delete (edit only): single-confirm via confirmationDialog — cascade removes the item (D-22).
/// Cost input: `.keyboardType(.decimalPad)`, parsed to `Double?` (T-03-08 mitigated).
struct CollectionItemEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Mode

    private enum EditorMode {
        case create(Collection)
        case edit(CollectionItem)
    }

    private let editorMode: EditorMode

    /// Set only via `init(collection:promotingIdea:)` — nil for the normal create/edit
    /// inits. Drives the post-save consume call (T-05-04); no extra domain gate is
    /// needed here — picking the collection already implies its domain (S7).
    private let sourceIdea: Idea?

    // MARK: - Field state

    @State private var title: String
    @State private var noteText: String
    @State private var urlText: String
    @State private var costText: String

    // MARK: - UI state

    @State private var showDeleteConfirm = false

    // MARK: - Init

    init(collection: Collection) {
        self.editorMode = .create(collection)
        self.sourceIdea = nil
        _title = State(initialValue: "")
        _noteText = State(initialValue: "")
        _urlText = State(initialValue: "")
        _costText = State(initialValue: "")
    }

    init(item: CollectionItem) {
        self.editorMode = .edit(item)
        self.sourceIdea = nil
        _title = State(initialValue: item.title)
        _noteText = State(initialValue: item.note ?? "")
        _urlText = State(initialValue: item.sourceURL ?? "")
        _costText = State(initialValue: item.cost.map { String(format: "%.2f", $0) } ?? "")
    }

    /// Promote-to-Collection entry point (IDEA-04/IDEA-05). The collection is already
    /// resolved by the caller (`PromoteToCollectionPicker`) — no extra domain gate needed.
    init(collection: Collection, promotingIdea idea: Idea) {
        self.editorMode = .create(collection)
        self.sourceIdea = idea
        _title = State(initialValue: idea.title)
        _noteText = State(initialValue: "")
        _urlText = State(initialValue: idea.url ?? "")
        _costText = State(initialValue: "")
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Form {
                titleSection(theme: theme)
                noteSection(theme: theme)
                urlSection(theme: theme)
                costSection(theme: theme)

                if case .edit(let item) = editorMode {
                    deleteSection(item: item, theme: theme)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveCTAButton(theme: theme)
                }
            }
            .confirmationDialog(
                "Delete this item?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                deleteDialogActions
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    // MARK: - Form sections

    private func titleSection(theme: Theme) -> some View {
        Section {
            TextField("Item title", text: $title)
                .font(theme.typography.body)

            if trimmedTitle.isEmpty {
                Text("Give this a name to continue.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        } header: {
            Text("Title")
                .font(theme.typography.headline)
        }
    }

    private func noteSection(theme: Theme) -> some View {
        Section {
            TextEditor(text: $noteText)
                .font(theme.typography.body)
                .frame(minHeight: 80)
        } header: {
            Text("Note")
                .font(theme.typography.headline)
        }
    }

    private func urlSection(theme: Theme) -> some View {
        Section {
            TextField("https://example.com", text: $urlText)
                .font(theme.typography.body)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("URL")
                .font(theme.typography.headline)
        }
    }

    private func costSection(theme: Theme) -> some View {
        Section {
            TextField("0.00", text: $costText)
                .font(theme.typography.body)
                .keyboardType(.decimalPad)
        } header: {
            Text("Cost")
                .font(theme.typography.headline)
        }
    }

    @ViewBuilder
    private func deleteSection(item: CollectionItem, theme: Theme) -> some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Item")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.danger)
            }
        }
    }

    // MARK: - Save CTA

    private func saveCTAButton(theme: Theme) -> some View {
        Button(saveCTATitle) {
            saveItem()
        }
        .disabled(trimmedTitle.isEmpty)
        .font(theme.typography.headline)
    }

    // MARK: - Delete dialog

    @ViewBuilder
    private var deleteDialogActions: some View {
        Button("Delete Item", role: .destructive) {
            if case .edit(let item) = editorMode {
                modelContext.delete(item)
                try? modelContext.save()
                dismiss()
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Helpers

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var navigationTitle: String {
        switch editorMode {
        case .create: return "New Item"
        case .edit:   return "Edit Item"
        }
    }

    private var saveCTATitle: String {
        switch editorMode {
        case .create: return "Add Item"
        case .edit:   return "Save Changes"
        }
    }

    /// Parse cost from decimalPad text → Double?. Invalid text yields nil (T-03-08).
    private var parsedCost: Double? {
        let trimmed = costText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Double(trimmed)
    }

    private var storedURL: String? {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var storedNote: String? {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func saveItem() {
        let trimmed = trimmedTitle
        guard !trimmed.isEmpty else { return }

        switch editorMode {
        case .create(let collection):
            let nextSortIndex = (collection.items.map(\.sortIndex).max() ?? -1) + 1
            let newItem = CollectionItem(
                title: trimmed,
                sortIndex: nextSortIndex,
                note: storedNote,
                sourceURL: storedURL,
                cost: parsedCost
            )
            newItem.collection = collection
            modelContext.insert(newItem)
            try? modelContext.save()

            // Consume the source idea only after a successful promote-Save (T-05-04) —
            // never before. No backref is set on the CollectionItem (D-07).
            if let sourceIdea {
                PromoteService.archiveAndForwardLink(idea: sourceIdea, as: .collectionItem, targetID: newItem.id)
                try? modelContext.save()
            }

        case .edit(let item):
            item.title = trimmed
            item.note = storedNote
            item.sourceURL = storedURL
            item.cost = parsedCost
            try? modelContext.save()
        }

        dismiss()
    }
}
