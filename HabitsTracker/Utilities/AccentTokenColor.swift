import SwiftUI
import DesignKit

/// App-level resolver mapping a stored `colorToken` string to one of the five
/// "Balanced Luxury" accent Colors. Lives in the app target (NOT DesignKit, §9.14)
/// because it maps an app-specific stored string to DesignKit accents — extract to
/// DesignKit only once a second app proves the same need (§4).
///
/// This is the single place a `Domain.colorToken` becomes a `Color`. The Hub grid
/// (DOM-03) and the 5-swatch color picker (D-17) both consume it. The token set is
/// closed to the five accents; any unknown/legacy token resolves to a safe on-palette
/// fallback (forest accent) so the UI never crashes and never goes off-brand.
///
/// Colors are sourced from DesignKit's `PresetCatalog` — each token maps to its matching
/// `ThemePreset` case, and the accent is read from `anchors(for: scheme).accent` — no
/// literal color constructors anywhere in this resolver (CLAUDE.md §1 / §9.4).
func accentColor(forToken token: String, scheme: ColorScheme) -> Color {
    let preset = themePreset(forToken: token)
    return PresetCatalog.theme(for: preset).anchors(for: scheme).accent
}

/// Maps a `colorToken` string to its DesignKit `ThemePreset`. The five valid accent
/// tokens map 1:1; `"oxblood"` is accepted as an alias for maroon. Any other value
/// (legacy/unknown) falls back to `.forest` — the safe, on-palette default.
private func themePreset(forToken token: String) -> ThemePreset {
    switch token {
    case "forest":            return .forest
    case "navy":              return .navy
    case "maroon", "oxblood": return .maroon
    case "walnut":            return .walnut
    case "stone":             return .stone
    default:                  return .forest
    }
}
