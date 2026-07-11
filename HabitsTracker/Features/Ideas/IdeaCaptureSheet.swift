import SwiftUI
import SwiftData
import DesignKit

/// Shared title-only create/edit sheet for `Idea` (S2, IDEA-01 / IDEA-02, D-08).
///
/// Supports two modes:
///   - Create: `IdeaCaptureSheet(domain:)` — inserts a new Idea on save. Passing
///     `nil` (the default, used by the global quick-add on Today) creates an
///     unfiled idea that surfaces in the Hub inbox; passing a domain pre-files
///     it (place-first, in-domain "+").
///   - Edit: `IdeaCaptureSheet(idea:)` — mutates the existing idea's title in
///     place on save; also exposes a destructive hard-delete confirm (the
///     mis-capture escape hatch).
///
/// Genuinely title-only (D-08 literal) — deliberately lighter than
/// `RuleEditorView`/`ClipEditorView`: a single field, no `Form` sections, and
/// no note/url/domain pickers exposed. `Idea.note`/`Idea.url` are promote-carry
/// plumbing this sheet never writes to (05-UI-SPEC Open Item #1).
///
/// Fill-then-commit (D-04 precedent): the Idea is constructed and inserted only
/// inside the Save action — Cancel dismisses without inserting/changing anything.
struct IdeaCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Mode

    private enum Mode {
        case create(domain: Domain?)
        case edit(idea: Idea)
    }

    private let mode: Mode

    // MARK: - Field state

    @State private var title: String
    @FocusState private var titleFieldIsFocused: Bool

    // MARK: - UI state

    @State private var showDeleteConfirm = false

    // MARK: - Init

    init(domain: Domain? = nil) {
        self.mode = .create(domain: domain)
        _title = State(initialValue: "")
    }

    init(idea: Idea) {
        self.mode = .edit(idea: idea)
        _title = State(initialValue: idea.title)
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                titleField(theme: theme)

                if case .edit = mode {
                    deleteRow(theme: theme)
                }

                Spacer()
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.background.ignoresSafeArea())
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
                "Delete this idea?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                deleteDialogActions
            } message: {
                Text("This can't be undone.")
            }
            .onAppear {
                titleFieldIsFocused = true
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Title field

    private func titleField(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text("Title")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)

            TextField("What's the idea?", text: $title)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .focused($titleFieldIsFocused)
                .accessibilityLabel("Idea title")

            if trimmedTitle.isEmpty {
                Text("Give this a name to continue.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        }
    }

    // MARK: - Delete (edit mode only)

    private func deleteRow(theme: Theme) -> some View {
        Button(role: .destructive) {
            showDeleteConfirm = true
        } label: {
            Text("Delete Idea")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.danger)
                .frame(minHeight: 44)
        }
    }

    @ViewBuilder
    private var deleteDialogActions: some View {
        Button("Delete Idea", role: .destructive) {
            if case .edit(let idea) = mode {
                modelContext.delete(idea)
                try? modelContext.save()
                dismiss()
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Save CTA

    private func saveCTAButton(theme: Theme) -> some View {
        Button(saveCTATitle) {
            saveIdea()
        }
        .disabled(trimmedTitle.isEmpty)
        .font(theme.typography.headline)
    }

    // MARK: - Helpers

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var navigationTitle: String {
        switch mode {
        case .create: return "New Idea"
        case .edit:   return "Edit Idea"
        }
    }

    private var saveCTATitle: String {
        switch mode {
        case .create: return "Add Idea"
        case .edit:   return "Save Changes"
        }
    }

    private func saveIdea() {
        let trimmed = trimmedTitle
        guard !trimmed.isEmpty else { return }

        switch mode {
        case .create(let domain):
            let idea = Idea(title: trimmed, domain: domain)
            modelContext.insert(idea)

        case .edit(let idea):
            idea.title = trimmed
        }

        try? modelContext.save()
        dismiss()
    }
}
