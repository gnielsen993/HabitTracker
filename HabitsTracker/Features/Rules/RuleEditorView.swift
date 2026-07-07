import SwiftUI
import SwiftData
import DesignKit

/// Create/edit form sheet for a `Rule` (S3, RULE-01 / RULE-05).
///
/// Supports two modes:
///   - Create: `RuleEditorView(domain:)` — inserts a new Rule on save, pre-filed
///     under the given domain; save CTA reads "Add Rule".
///   - Edit: `RuleEditorView(rule:)` — mutates the existing rule in place on save;
///     save CTA reads "Save Changes". Also exposes archive/unarchive and delete-with-
///     stems soft-confirm dialog.
///
/// Shaped like `HabitEditorView`: Form, @Environment dismiss + modelContext,
/// @Query domain picker, try? modelContext.save() + dismiss() on save.
struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    // MARK: - Mode

    private enum EditorMode {
        case create(domain: Domain)
        case edit(rule: Rule)
    }

    private let editorMode: EditorMode

    // MARK: - Field state (bound to form controls)

    @State private var title: String
    @State private var bodyText: String
    @State private var sourceURLText: String
    @State private var selectedDomainID: UUID?

    // MARK: - UI state

    @State private var showDeleteConfirm = false

    // MARK: - Init

    init(domain: Domain) {
        self.editorMode = .create(domain: domain)
        _title = State(initialValue: "")
        _bodyText = State(initialValue: "")
        _sourceURLText = State(initialValue: "")
        _selectedDomainID = State(initialValue: domain.id)
    }

    init(rule: Rule) {
        self.editorMode = .edit(rule: rule)
        _title = State(initialValue: rule.title)
        _bodyText = State(initialValue: rule.body)
        _sourceURLText = State(initialValue: rule.sourceURL ?? "")
        _selectedDomainID = State(initialValue: rule.domain?.id)
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Form {
                titleSection(theme: theme)
                bodySection(theme: theme)
                sourceURLSection(theme: theme)
                domainSection(theme: theme)

                if case .edit(let rule) = editorMode {
                    archiveSection(rule: rule, theme: theme)
                    deleteSection(rule: rule, theme: theme)
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

    private func titleSection(theme: Theme) -> some View {
        Section {
            TextField("Rule title", text: $title)
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

    private func bodySection(theme: Theme) -> some View {
        Section {
            TextEditor(text: $bodyText)
                .font(theme.typography.body)
                .frame(minHeight: 80)
        } header: {
            Text("Body")
                .font(theme.typography.headline)
        }
    }

    private func sourceURLSection(theme: Theme) -> some View {
        Section {
            TextField("https://example.com", text: $sourceURLText)
                .font(theme.typography.body)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        } header: {
            Text("Source URL")
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
    private func archiveSection(rule: Rule, theme: Theme) -> some View {
        Section {
            Button {
                rule.isArchived.toggle()
                try? modelContext.save()
                dismiss()
            } label: {
                Text(rule.isArchived ? "Unarchive Rule" : "Archive rule")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .accessibilityLabel(rule.isArchived ? "Unarchive Rule" : "Archive rule")
        }
    }

    @ViewBuilder
    private func deleteSection(rule: Rule, theme: Theme) -> some View {
        Section {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Text("Delete Rule")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.danger)
            }
        }
    }

    // MARK: - Save CTA

    private func saveCTAButton(theme: Theme) -> some View {
        Button(saveCTATitle) {
            saveRule()
        }
        .disabled(trimmedTitle.isEmpty)
        .font(theme.typography.headline)
    }

    // MARK: - Delete Dialog

    private var deleteDialogTitle: String {
        "Delete this rule?"
    }

    @ViewBuilder
    private var deleteDialogActions: some View {
        Button("Delete Rule", role: .destructive) {
            if case .edit(let rule) = editorMode {
                modelContext.delete(rule)
                try? modelContext.save()
                dismiss()
            }
        }
        Button("Cancel", role: .cancel) {}
    }

    @ViewBuilder
    private var deleteDialogMessage: some View {
        if case .edit(let rule) = editorMode {
            let stemCount = rule.stemmedHabits.count
            if stemCount > 0 {
                Text("This rule has \(stemCount) stemmed habit\(stemCount == 1 ? "" : "s"). They'll be kept — only the rule is deleted.")
            } else {
                Text("This can't be undone.")
            }
        }
    }

    // MARK: - Helpers

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var navigationTitle: String {
        switch editorMode {
        case .create: return "New Rule"
        case .edit:   return "Edit Rule"
        }
    }

    private var saveCTATitle: String {
        switch editorMode {
        case .create: return "Add Rule"
        case .edit:   return "Save Changes"
        }
    }

    private func resolvedDomain() -> Domain? {
        guard let id = selectedDomainID else { return nil }
        return domains.first(where: { $0.id == id })
    }

    private func saveRule() {
        let trimmed = trimmedTitle
        guard !trimmed.isEmpty else { return }

        let urlString = sourceURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        let storedURL = urlString.isEmpty ? nil : urlString

        switch editorMode {
        case .create:
            let rule = Rule(
                title: trimmed,
                body: bodyText,
                sourceURL: storedURL,
                domain: resolvedDomain()
            )
            modelContext.insert(rule)

        case .edit(let rule):
            rule.title = trimmed
            rule.body = bodyText
            rule.sourceURL = storedURL
            rule.domain = resolvedDomain()
        }

        try? modelContext.save()
        dismiss()
    }
}
