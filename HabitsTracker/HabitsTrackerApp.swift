import SwiftUI
import SwiftData

@main
struct HabitsTrackerApp: App {
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            AppBootstrapView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.preferredColorScheme)
        }
        .modelContainer(for: [
            Domain.self,
            Habit.self,
            DailyEntry.self,
            HabitState.self,
            Rule.self,
            Collection.self,
            CollectionItem.self
        ])
    }
}
