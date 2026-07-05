import SwiftUI
import DesignKit

// Stub — full implementation in Task 3 (02-02)
struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private enum Mode {
        case create(domain: Domain)
        case edit(rule: Rule)
    }

    private let mode: Mode

    init(domain: Domain) {
        self.mode = .create(domain: domain)
    }

    init(rule: Rule) {
        self.mode = .edit(rule: rule)
    }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        Text("Rule Editor")
            .font(theme.typography.title)
            .foregroundStyle(theme.colors.textPrimary)
    }
}
