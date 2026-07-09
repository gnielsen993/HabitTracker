import SwiftUI
import DesignKit

/// A data-driven row displaying one `Clip` inside the Clips section of `DomainDetailView`.
/// Owns no fetch/query and no direct data-store access — the parent supplies a
/// `Clip` value (§9.2).
///
/// Visual: `DKCard` surface; headline title (2-line cap) + optional caption line
/// showing the `tag` when present; trailing `DKBadge` status chip that tap-toggles
/// `saved ↔ acted` with `.sensoryFeedback` (D-04, D-05, D-08). Plain two-way toggle —
/// no long-press reset menu (D-05, unlike the Collections terminal-clamped chip).
struct ClipRow: View {
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let clip: Clip

    /// Incremented on every chip tap to trigger sensory feedback on the toggle.
    @State private var tapCounter: Int = 0

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        DKCard(theme: theme) {
            HStack(alignment: .center, spacing: theme.spacing.m) {
                // Text block owns the row's navigation affordance: combined into a
                // single VoiceOver element so the status-chip Button stays a
                // separate, reachable control (WR-01 / WR-04).
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(clip.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    if let tag = clip.tag, !tag.isEmpty {
                        Text(tag)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel)

                statusChip(theme: theme)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        }
    }

    // MARK: - Status chip (D-04, D-05, D-08)

    /// A `Button` (not a raw `.onTapGesture`) so the tap is not swallowed by the
    /// enclosing `NavigationLink` and so VoiceOver exposes it as an activatable
    /// control (WR-01 / WR-04). `.buttonStyle(.plain)` keeps the DKBadge visual.
    private func statusChip(theme: Theme) -> some View {
        Button {
            tapCounter += 1
            clip.status = clip.status == .saved ? .acted : .saved
        } label: {
            DKBadge(statusLabel, theme: theme)
                .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: tapCounter)
        .accessibilityLabel("Status: \(statusLabel), \(clip.title)")
        .accessibilityHint("Toggles between saved and acted")
    }

    // MARK: - Helpers

    private var statusLabel: String {
        clip.status == .saved ? "Saved" : "Acted"
    }

    private var accessibilityLabel: String {
        var label = "\(clip.title), status: \(statusLabel)"
        if let tag = clip.tag, !tag.isEmpty {
            label += ", tag: \(tag)"
        }
        return label
    }
}
