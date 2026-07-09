import SwiftUI
import SwiftData
import DesignKit
import os.log

private let logger = Logger(subsystem: "lauterstar.HabitsTracker", category: "ClipEditorView")

/// Create/edit form sheet for a `Clip` (S3, CLIP-01 / CLIP-02).
///
/// Supports two modes:
///   - Create: `ClipEditorView(domain:)` — inserts a new Clip on save, pre-filed
///     under the given domain; save CTA reads "Add Clip".
///   - Edit: `ClipEditorView(clip:)` — mutates the existing clip in place on save;
///     save CTA reads "Save Changes". Also exposes a destructive delete-with-confirm
///     dialog (D-11).
///
/// Shaped like `RuleEditorView`: Form, @Environment dismiss + modelContext,
/// @Query domain picker, try? modelContext.save() + dismiss() on save.
///
/// D-02: typing a URL while the Title field has not been manually edited prefills
/// Title from `ClipTitleSuggestion.suggest(from:)`. Once the user edits Title by
/// hand, further URL edits never overwrite it again — never fights the user's
/// keystrokes.
struct ClipEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    // MARK: - Mode

    private enum EditorMode {
        case create(domain: Domain)
        case edit(clip: Clip)
    }

    private let editorMode: EditorMode

    // MARK: - Field state (bound to form controls)

    @State private var urlText: String
    @State private var title: String
    @State private var noteText: String
    @State private var tagText: String
    @State private var selectedDomainID: UUID?

    // MARK: - D-02 title-suggestion wiring

    /// Set true the moment the user edits Title directly; once true, URL edits
    /// never overwrite Title again.
    @State private var titleWasManuallyEdited = false
    /// Guards the suggestion's own write to `title` so it does not flip
    /// `titleWasManuallyEdited` (only a *direct* user edit should flip it).
    @State private var isApplyingTitleSuggestion = false

    // MARK: - UI state

    @State private var showDeleteConfirm = false

    // MARK: - Init

    init(domain: Domain) {
        self.editorMode = .create(domain: domain)
        _urlText = State(initialValue: "")
        _title = State(initialValue: "")
        _noteText = State(initialValue: "")
        _tagText = State(initialValue: "")
        _selectedDomainID = State(initialValue: domain.id)
    }

    init(clip: Clip) {
        self.editorMode = .edit(clip: clip)
        _urlText = State(initialValue: clip.url)
        _title = State(initialValue: clip.title)
        _noteText = State(initialValue: clip.note ?? "")
        _tagText = State(initialValue: clip.tag ?? "")
        _selectedDomainID = State(initialValue: clip.domain?.id)
        // Editing an existing clip already has a user-authored title — never
        // let a later URL tweak silently overwrite it.
        _titleWasManuallyEdited = State(initialValue: true)
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Form {
                urlSection(theme: theme)
                titleSection(theme: theme)
                noteSection(theme: theme)
                tagSection(theme: theme)
                domainSection(theme: theme)

                if case .edit = editorMode {
                    deleteSection(theme: theme)
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
                deleteDialogTitle,
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                deleteDialogActions
            } message: {
                deleteDialogMessage
            }
        }
    }

    // MARK: - Form Sections

    private func urlSection(theme: Theme) -> some View {
        Section {
            TextField("https://example.com", text: $urlText)
                .font(theme.typography.body)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: urlText) { _, newValue in
                    guard !titleWasManuallyEdited else { return }
                    isApplyingTitleSuggestion = true
                    title = ClipTitleSuggestion.suggest(from: newValue)
                }
        } header: {
            Text("URL")
                .font(theme.typography.headline)
        }
    }

    private func titleSection(theme: Theme) -> some View {
        Section {
            TextField("Clip title", text: $title)
                .font(theme.typography.body)
                .onChange(of: title) { _, _ in
                    if isApplyingTitleSuggestion {
                        isApplyingTitleSuggestion = false
                    } else {
                        titleWasManuallyEdited = true
                    }
                }

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

    private func tagSection(theme: Theme) -> some View {
        Section {
            TextField("Tag (optional)", text: $tagText)
                .font(theme.typography.body)
        } header: {
            Text("Tag")
                .font(theme.typography.headline)
        }
    }

    private func domainSection(theme: Theme) -> some View {
        Section {
            Picker("Domain", selection: $selectedDomainID) {
                Text("None").tag(UUID?.none)
                ForEach(domains, id: \.id) { domain in
                    Text(domain.name).tag(UUID?.some(domain.id))
                }
            }
            .font(theme.typography.body)
        } header: {
            Text("Domain")
                .font(theme.typography.headline)
        }
    }

    @ViewBuilder
    private func deleteSection(theme: Theme) -> some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Clip")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.danger)
            }
        }
    }

    // MARK: - Save CTA

    private func saveCTAButton(theme: Theme) -> some View {
        Button(saveCTATitle) {
            saveClip()
        }
        .disabled(trimmedTitle.isEmpty || trimmedURL.isEmpty)
        .font(theme.typography.headline)
    }

    // MARK: - Delete Dialog

    private var deleteDialogTitle: String {
        "Delete this clip?"
    }

    @ViewBuilder
    private var deleteDialogActions: some View {
        Button("Delete Clip", role: .destructive) {
            if case .edit(let clip) = editorMode {
                modelContext.delete(clip)
                try? modelContext.save()
                dismiss()
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    private var deleteDialogMessage: some View {
        Text("This can't be undone.")
    }

    // MARK: - Helpers

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedURL: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var navigationTitle: String {
        switch editorMode {
        case .create: return "New Clip"
        case .edit:   return "Edit Clip"
        }
    }

    private var saveCTATitle: String {
        switch editorMode {
        case .create: return "Add Clip"
        case .edit:   return "Save Changes"
        }
    }

    private func resolvedDomain() -> Domain? {
        guard let id = selectedDomainID else { return nil }
        return domains.first(where: { $0.id == id })
    }

    /// Store-only URL normalization (Claude's Discretion): prepend `https://`
    /// when the trimmed URL has no scheme so `openURL`/`Link` in
    /// `ClipDetailView` can open it. Never fetched, never validated over the
    /// network — a syntactically-odd URL is accepted as-is and simply may not
    /// open (graceful, no crash, no data loss — T-04-05).
    private func normalizedURL(from raw: String) -> String {
        guard !raw.contains("://") else { return raw }
        logger.debug("Normalizing scheme-less clip URL by prepending https://")
        return "https://" + raw
    }

    private func saveClip() {
        let trimmedTitleValue = trimmedTitle
        let trimmedURLValue = trimmedURL
        guard !trimmedTitleValue.isEmpty, !trimmedURLValue.isEmpty else { return }

        let storedURL = normalizedURL(from: trimmedURLValue)
        let storedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let storedTag = tagText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch editorMode {
        case .create:
            let clip = Clip(
                title: trimmedTitleValue,
                url: storedURL,
                note: storedNote.isEmpty ? nil : storedNote,
                tag: storedTag.isEmpty ? nil : storedTag,
                domain: resolvedDomain()
            )
            modelContext.insert(clip)

        case .edit(let clip):
            clip.title = trimmedTitleValue
            clip.url = storedURL
            clip.note = storedNote.isEmpty ? nil : storedNote
            clip.tag = storedTag.isEmpty ? nil : storedTag
            clip.domain = resolvedDomain()
        }

        try? modelContext.save()
        dismiss()
    }
}
