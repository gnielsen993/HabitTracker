import SwiftUI
import DesignKit

// Stub — full implementation in Task 2 (02-02)
struct RuleDetailView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let rule: Rule

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        Text(rule.title)
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.textPrimary)
    }
}
