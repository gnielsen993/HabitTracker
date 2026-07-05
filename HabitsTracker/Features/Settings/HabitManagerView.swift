import SwiftUI
import SwiftData
import DesignKit

struct HabitManagerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Habit.name) private var habits: [Habit]

    @State private var searchText = ""
    @State private var filterMode: HabitMode?
    @State private var editingHabit: Habit?
    @State private var creatingHabit = false

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        List {
            Section {
                TextField("Search", text: $searchText)
                Picker("Mode", selection: $filterMode) {
                    Text("All").tag(HabitMode?.none)
                    Text("Required").tag(HabitMode?.some(.required))
                    Text("Optional").tag(HabitMode?.some(.optional))
                }
                .pickerStyle(.segmented)
            }

            Section("Habits") {
                ForEach(filteredHabits, id: \.id) { habit in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(habit.name)
                                .foregroundStyle(theme.colors.textPrimary)
                            Text(habit.mode == .required ? "Required" : "Optional")
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        Spacer()
                        Button("Edit") { editingHabit = habit }
                            .foregroundStyle(theme.colors.accentPrimary)
                    }
                }
            }

            Section {
                Button("Add Habit") {
                    creatingHabit = true
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.colors.background)
        .navigationTitle("Habits")
        .sheet(item: $editingHabit) { habit in
            HabitEditorView(habit: habit)
        }
        .sheet(isPresented: $creatingHabit) {
            HabitCreateSheet(source: .manual)
        }
    }

    private var filteredHabits: [Habit] {
        habits
            .filter {
                searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
            }
            .filter {
                guard let filterMode else { return true }
                return $0.mode == filterMode
            }
    }
}
