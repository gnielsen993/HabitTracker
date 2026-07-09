import SwiftUI
import DesignKit

/// The reference-first read surface for a `Clip` (S2, CLIP-02 / CLIP-03 / CLIP-04).
///
/// Data-driven: takes a `Clip` value; declares NO `NavigationStack` of its own —
/// it nests under the Hub's stack (mirrors `RuleDetailView`). The toolbar "Edit"
/// button presents `ClipEditorView(clip:)` as a sheet.
///
/// Block ordering per 04-UI-SPEC S2:
///   1. Header — clip title (+ optional domain glyph)
///   2. Status/Tag — tap-toggle status chip (identical control to `ClipRow`) +
///      optional tag pill, both using the same `DKBadge` styling (D-04)
///   3. Open Link — a full-width primary CTA (D-08's deliberate upgrade over the
///      Rules bordered-link-block precedent) that opens `clip.url` via `Link` —
///      stored + opened only, never fetched (offline gate, T-04-06)
///   4. Note — omitted when nil/empty
struct ClipDetailView: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    let clip: Clip

    @State private var editingClip = false
    @State private var chipTapCounter: Int = 0

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                headerBlock(theme: theme)
                statusTagBlock(theme: theme)
                openLinkCTA(theme: theme)

                if let note = clip.note, !note.isEmpty {
                    noteBlock(note: note, theme: theme)
                }
            }
            .padding(theme.spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    editingClip = true
                }
                .foregroundStyle(theme.colors.accentPrimary)
            }
        }
        .sheet(isPresented: $editingClip) { ClipEditorView(clip: clip) }
    }

    // MARK: - Block 1: Header

    private func headerBlock(theme: Theme) -> some View {
        HStack(alignment: .top, spacing: theme.spacing.m) {
            if let domain = clip.domain {
                Image(systemName: domain.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(
                        HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme)
                    )
                    .accessibilityHidden(true)
            }

            Text(clip.title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(headerAccessibilityLabel)
    }

    private var headerAccessibilityLabel: String {
        "\(clip.title), clip, status: \(statusLabel)\(tagAccessibilitySuffix)"
    }

    // MARK: - Block 2: Status + Tag

    private func statusTagBlock(theme: Theme) -> some View {
        HStack(spacing: theme.spacing.s) {
            // Button (not a raw .onTapGesture) so VoiceOver exposes it as an
            // activatable control with a reliable double-tap action (WR-04, §9.15).
            // .buttonStyle(.plain) preserves the DKBadge visual.
            Button {
                chipTapCounter += 1
                clip.status = clip.status == .saved ? .acted : .saved
            } label: {
                DKBadge(statusLabel, theme: theme)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(weight: .light), trigger: chipTapCounter)
            .accessibilityLabel("Status: \(statusLabel), \(clip.title)")
            .accessibilityHint("Toggles between saved and acted")

            if let tag = clip.tag, !tag.isEmpty {
                DKBadge(tag, theme: theme)
                    .accessibilityLabel("Tag: \(tag)")
            }
        }
    }

    // MARK: - Block 3: Open Link (primary CTA, D-08)

    @ViewBuilder
    private func openLinkCTA(theme: Theme) -> some View {
        if let url = URL(string: clip.url) {
            let host = url.host ?? clip.url

            Link(destination: url) {
                Text("Open Link")
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.background)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(theme.colors.accentPrimary)
                    .cornerRadius(theme.radii.button)
            }
            .accessibilityLabel("Open link, \(host)")
        } else {
            // T-04-05: a malformed clip.url must never crash the detail view —
            // degrade to a disabled, no-op affordance instead of force-unwrapping.
            Text("Open Link")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(theme.colors.surface)
                .cornerRadius(theme.radii.button)
                .accessibilityLabel("Open link unavailable, invalid URL")
        }
    }

    // MARK: - Block 4: Note (conditional)

    private func noteBlock(note: String, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("Note")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)
            Text(note)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private var statusLabel: String {
        clip.status == .saved ? "Saved" : "Acted"
    }

    private var tagAccessibilitySuffix: String {
        guard let tag = clip.tag, !tag.isEmpty else { return "" }
        return ", tag: \(tag)"
    }
}
