import SwiftUI
import SwiftData
import DesignKit

/// Reusable, data-driven row for one `Idea` (S6, IDEA-03, D-05, D-10).
///
/// Shared between `InboxView` (05-08) and the Ideas section of `DomainDetailView`
/// (05-09) — takes only an `Idea` value (§9.2); owns no `@Query` for its subject
/// (the `Domain` query here is auxiliary picker data for the File menu, not the
/// row's core subject).
///
/// Row 1 tap opens `IdeaCaptureSheet(idea:)` in edit mode — the row's only
/// "detail" affordance (D-08, deliberately no `IdeaDetailView`). Row 2 offers a
/// File pill (a domain `Menu`, shown only when `idea.domain == nil`) and a
/// Promote pill (always shown, routes into the prefilled target editors).
struct IdeaRow: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    let idea: Idea

    @State private var editingIdea = false
    @State private var promoteRoute: PromoteRoute?
    @State private var confirmingDelete = false

    /// Promote destination (S7, IDEA-04/IDEA-05) - drives `.sheet(item:)` presentation.
    private enum PromoteRoute: Identifiable {
        case rule
        case habit
        case collection

        var id: Self { self }
    }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Button {
                editingIdea = true
            } label: {
                titleBlock(theme: theme)
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.spacing.s) {
                    moveMenu(theme: theme)
                    turnIntoMenu(theme: theme)
                    actionButton("Add to List", systemImage: "list.bullet", theme: theme) {
                        promoteRoute = .collection
                    }
                    actionButton("Archive", systemImage: "archivebox", theme: theme) {
                        idea.isArchived = true
                        try? modelContext.save()
                    }
                    actionButton("Delete", systemImage: "trash", theme: theme) {
                        confirmingDelete = true
                    }
                }
            }

            Divider()
                .overlay(theme.colors.border)
        }
        .sheet(isPresented: $editingIdea) {
            IdeaCaptureSheet(idea: idea)
        }
        .sheet(item: $promoteRoute) { route in
            switch route {
            case .rule:
                RuleEditorView(promotingIdea: idea)
            case .habit:
                HabitCreateSheet(source: .idea(idea), onSaved: { habit in
                    PromoteService.archiveAndForwardLink(idea: idea, as: .habit, targetID: habit.id)
                    try? modelContext.save()
                })
            case .collection:
                PromoteToCollectionPicker(idea: idea)
            }
        }
        .confirmationDialog("Delete this thought?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Thought", role: .destructive) {
                modelContext.delete(idea)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: - Row 1 (title + optional note)

    private func titleBlock(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(idea.title)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            if let note = idea.note, !note.isEmpty {
                Text(note)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(titleAccessibilityLabel)
    }

    private var titleAccessibilityLabel: String {
        var label = "\(idea.title), thought"
        if let note = idea.note, !note.isEmpty {
            label += ", \(note)"
        }
        return label
    }

    // MARK: - File pill (Row 2, D-10)

    private func moveMenu(theme: Theme) -> some View {
        Menu {
            ForEach(domains) { domain in
                Button(domain.name) {
                    idea.domain = domain
                    try? modelContext.save()
                }
            }
        } label: {
            pillLabel(systemImage: "folder", text: "Move to Area", theme: theme)
        }
        .accessibilityLabel("Move thought to an area")
    }

    // MARK: - Promote pill (Row 2, always shown, D-07)

    private func turnIntoMenu(theme: Theme) -> some View {
        Menu {
            Button("Turn into Habit") { promoteRoute = .habit }
            Button("Turn into Principle") { promoteRoute = .rule }
        } label: {
            pillLabel(systemImage: "arrow.triangle.branch", text: "Turn into…", theme: theme)
        }
        .accessibilityLabel("Turn thought into a habit or principle")
    }

    private func actionButton(
        _ title: String,
        systemImage: String,
        theme: Theme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            pillLabel(systemImage: systemImage, text: title, theme: theme)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) thought")
    }

    // MARK: - Pill recipe (DKBadge-style, tokens only)

    private func pillLabel(systemImage: String, text: String, theme: Theme) -> some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(theme.typography.caption.weight(.semibold))
        .foregroundStyle(theme.colors.accentPrimary)
        .padding(.horizontal, theme.spacing.s)
        .frame(minHeight: 44)
        .background(theme.colors.highlight)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous))
        .contentShape(Rectangle())
    }
}
