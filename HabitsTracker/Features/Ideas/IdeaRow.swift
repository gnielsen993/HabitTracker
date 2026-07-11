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

    /// Promote destination (S7, IDEA-04/IDEA-05) - drives `.sheet(item:)` presentation.
    private enum PromoteRoute: Identifiable {
        case rule
        case habit
        case collection

        var id: Self { self }
    }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.s) {
                Button {
                    editingIdea = true
                } label: {
                    titleBlock(theme: theme)
                }
                .buttonStyle(.plain)

                HStack(spacing: theme.spacing.s) {
                    if idea.domain == nil {
                        filePill(theme: theme)
                    }
                    promotePill(theme: theme)
                }
            }
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
        var label = "\(idea.title), idea"
        if let note = idea.note, !note.isEmpty {
            label += ", \(note)"
        }
        return label
    }

    // MARK: - File pill (Row 2, D-10)

    private func filePill(theme: Theme) -> some View {
        Menu {
            ForEach(domains) { domain in
                Button(domain.name) {
                    idea.domain = domain
                    try? modelContext.save()
                }
            }
        } label: {
            pillLabel(systemImage: "tray.and.arrow.down", text: "File", theme: theme)
        }
        .accessibilityLabel("File idea, choose a domain")
    }

    // MARK: - Promote pill (Row 2, always shown, D-07)

    private func promotePill(theme: Theme) -> some View {
        Menu {
            Button("Rule") { promoteRoute = .rule }
            Button("Habit") { promoteRoute = .habit }
            Button("Collection item") { promoteRoute = .collection }
        } label: {
            pillLabel(systemImage: "arrow.up.forward.circle", text: "Promote", theme: theme)
        }
        .accessibilityLabel("Promote idea, choose a type")
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
