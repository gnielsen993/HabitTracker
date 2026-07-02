import SwiftUI
import DesignKit

/// Closed 5-token accent swatch row for custom-domain creation (D-17).
///
/// Renders exactly the five "Balanced Luxury" accent tokens — forest, navy, maroon,
/// walnut, stone — each filled via `accentColor(forToken:scheme:)`. There is
/// deliberately NO color wheel and NO hex field: the selected swatch is the only writer
/// of `Domain.colorToken`, so the token is valid-by-construction and can never go
/// off-palette.
///
/// Data-driven (§9.2): the view owns no query, taking only a selection binding + theme.
struct DomainColorSwatchRow: View {
    @Binding var selection: String
    let theme: Theme
    let scheme: ColorScheme

    /// The closed accent token set (D-17). Order is stable for a deterministic row.
    static let tokens: [String] = ["forest", "navy", "maroon", "walnut", "stone"]

    private func displayName(for token: String) -> String { token.capitalized }

    var body: some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(Self.tokens, id: \.self) { token in
                swatch(for: token)
            }
        }
    }

    private func swatch(for token: String) -> some View {
        let isSelected = token == selection
        let fill = accentColor(forToken: token, scheme: scheme)

        return Button {
            selection = token
        } label: {
            Circle()
                .fill(fill)
                .frame(minWidth: 44, minHeight: 44)
                .overlay(
                    Circle()
                        .strokeBorder(
                            isSelected ? theme.colors.accentPrimary : theme.colors.border,
                            lineWidth: isSelected ? 3 : 1
                        )
                        .padding(isSelected ? theme.spacing.xs : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(displayName(for: token))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
