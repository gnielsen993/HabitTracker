import SwiftUI
import DesignKit

struct RootTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    private var theme: Theme {
        themeManager.theme(for: colorScheme)
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }

            // Hub tab slot is inserted here by plan 01-05 (depends on HubView),
            // reaching the final 4-tab IA Today / Hub / Progress / Settings.
            // The former Calendar tab now lives inside Progress behind a
            // Charts ⇄ Calendar segmented control (D-12/D-13).

            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(theme.colors.accentPrimary)
    }
}
