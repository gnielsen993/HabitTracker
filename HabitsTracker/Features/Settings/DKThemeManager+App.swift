import SwiftUI
import DesignKit

/// App-side conveniences on DesignKit's shared `ThemeManager` (`DKThemeManager`).
///
/// HabitsTracker previously wrapped `DKThemeManager` in a bespoke `ThemeManager`
/// `ObservableObject` that only forwarded `mode`/`preset`. That wrapper blocked
/// adoption of DesignKit's newer `DKThemePicker` (custom themes, preset chip
/// grid), so it was collapsed in favor of injecting `DKThemeManager` directly.
/// These two members preserve the only unique affordances the wrapper provided.
extension DKThemeManager {
    /// Resolve the active `Theme` for the current system color scheme.
    /// Mirrors the prior wrapper's `theme(for:)` naming so call sites are stable.
    func theme(for systemScheme: ColorScheme) -> Theme {
        theme(using: systemScheme)
    }

    /// Scheme to hand `.preferredColorScheme`. `nil` follows the system (System mode).
    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
