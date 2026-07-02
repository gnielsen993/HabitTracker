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

            HubView()
                .tabItem {
                    Label("Hub", systemImage: "square.grid.2x2")
                }

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
