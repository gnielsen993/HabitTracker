import SwiftUI
import DesignKit

/// Curated SF Symbol grid for custom-domain creation (D-16).
///
/// The icon set is a closed, hand-picked `[String]` of ~30 lifestyle-relevant SF
/// Symbols (consistent with the seeded domain glyphs) — there is deliberately NO full
/// system symbol browser and NO third-party icon dependency. This keeps every custom
/// domain on-brand (Balanced Luxury restraint) and `iconName` valid-by-construction.
///
/// Data-driven (§9.2): the view owns no query, taking only a selection binding + theme.
struct DomainIconPicker: View {
    @Binding var selection: String
    let theme: Theme

    /// Closed, curated SF Symbol set (~30). Includes the seeded domain glyphs plus
    /// lifestyle-relevant additions. Order is stable so the grid layout is deterministic.
    static let curatedSymbols: [String] = [
        // Seeded domain glyphs (kept consistent with SeedDataService)
        "checklist", "book", "sun.max", "heart", "figure.run", "person.2",
        "brain", "house", "dollarsign.circle", "paintbrush", "briefcase", "tray.full",
        "tshirt", "fork.knife", "banknote", "play.rectangle",
        // Lifestyle-relevant additions
        "music.note", "airplane", "cart", "dumbbell", "leaf", "camera",
        "gamecontroller", "cup.and.saucer", "moon.stars", "pawprint",
        "graduationcap", "wrench.and.screwdriver", "gift", "bicycle",
        "square.grid.2x2"
    ]

    /// Human-readable name for a symbol, used in the VoiceOver label (§9.15).
    private func humanName(for symbol: String) -> String {
        symbol
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 56), spacing: theme.spacing.m)],
            spacing: theme.spacing.m
        ) {
            ForEach(Self.curatedSymbols, id: \.self) { symbol in
                cell(for: symbol)
            }
        }
    }

    private func cell(for symbol: String) -> some View {
        let isSelected = symbol == selection

        return Button {
            selection = symbol
        } label: {
            Image(systemName: symbol)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.textPrimary)
                .frame(minWidth: 44, minHeight: 44)
                .frame(maxWidth: .infinity)
                .padding(theme.spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
                        .fill(isSelected ? theme.colors.fillSelected : theme.colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.chip, style: .continuous)
                        .strokeBorder(
                            isSelected ? theme.colors.accentPrimary : theme.colors.border,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(humanName(for: symbol))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
