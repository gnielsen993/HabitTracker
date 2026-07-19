import SwiftUI
import SwiftData
import DesignKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]

    @State private var saveError: String?
    @State private var noteIsExpanded = false
    @State private var doneIsExpanded = false
    @State private var completionFeedback = 0

    private let bootstrapService = BootstrapService()

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)
        let todayHabits = TodayEngine.requiredHabits(from: habits, on: .now)
        let weekHabits = TodayEngine.optionalHabits(from: habits)
        let unfinished = todayHabits.filter { !isCompleted($0) }
        let completed = todayHabits.filter(isCompleted)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: theme.spacing.xl) {
                    dayHeader(todayHabits: todayHabits, completed: completed.count, theme: theme)

                    if let focus = upNext(from: unfinished) {
                        upNextCard(focus, theme: theme)
                    } else if todayHabits.isEmpty && weekHabits.isEmpty {
                        emptyDay(theme: theme)
                    }

                    if !unfinished.isEmpty {
                        todayPlan(unfinished, theme: theme)
                    }

                    if !completed.isEmpty {
                        doneToday(completed, theme: theme)
                    }

                    if !weekHabits.isEmpty {
                        thisWeek(weekHabits, theme: theme)
                    }

                    dailyNote(theme: theme)
                }
                .padding(theme.spacing.l)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(theme.colors.background.ignoresSafeArea())
            .navigationTitle("Today")
            .alert("Save Error", isPresented: Binding(get: { saveError != nil }, set: { _ in saveError = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(saveError ?? "Unknown error")
            }
            .task {
                do {
                    _ = try bootstrapService.ensureDailyEntryExists(for: .now, context: modelContext)
                } catch {
                    saveError = error.localizedDescription
                }
            }
            .sensoryFeedback(.success, trigger: completionFeedback)
        }
    }

    private func dayHeader(todayHabits: [Habit], completed: Int, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.s) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)

            Text(greeting)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)

            Text(summary(todayHabits: todayHabits, completed: completed))
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func upNextCard(_ habit: Habit, theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            Text("UP NEXT")
                .font(theme.typography.caption.weight(.semibold))
                .foregroundStyle(theme.colors.accentPrimary)

            Text(habit.name)
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)

            if let area = habit.category {
                Label(area.name, systemImage: area.iconName)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            sevenDayTrail(for: habit, theme: theme)

            Button {
                toggle(habit)
            } label: {
                Label("Mark complete", systemImage: "checkmark")
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.surfaceElevated)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.vertical, theme.spacing.s)
                    .background(theme.colors.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.button, style: .continuous))
            }
            .accessibilityHint("Completes \(habit.name) and advances Up Next")
        }
        .padding(theme.spacing.l)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: theme.radii.card, style: .continuous)
                .stroke(theme.colors.border, lineWidth: 1)
        }
        .animation(reduceMotion ? nil : theme.motion.ease, value: habit.id)
    }

    private func sevenDayTrail(for habit: Habit, theme: Theme) -> some View {
        HStack(spacing: theme.spacing.s) {
            ForEach(lastSevenDays, id: \.self) { date in
                let completed = state(for: habit, on: date)?.isCompleted == true
                VStack(spacing: theme.spacing.xs) {
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(theme.typography.caption)
                    Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                        .accessibilityHidden(true)
                }
                .foregroundStyle(completed ? theme.colors.success : theme.colors.textTertiary)
                .accessibilityLabel("\(date.formatted(date: .abbreviated, time: .omitted)), \(completed ? "completed" : "not completed")")
            }
        }
    }

    private func todayPlan(_ unfinished: [Habit], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            DKSectionHeader("Today", subtitle: "Your plan", theme: theme)
            DKCard(theme: theme) {
                VStack(spacing: theme.spacing.s) {
                    ForEach(unfinished) { habit in
                        compactHabitRow(habit, theme: theme)
                    }
                }
            }
        }
    }

    private func doneToday(_ completed: [Habit], theme: Theme) -> some View {
        DisclosureGroup(isExpanded: $doneIsExpanded) {
            VStack(spacing: theme.spacing.s) {
                ForEach(completed) { habit in compactHabitRow(habit, theme: theme) }
            }
            .padding(.top, theme.spacing.s)
        } label: {
            Text("Done today · \(completed.count)")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .tint(theme.colors.accentPrimary)
    }

    private func compactHabitRow(_ habit: Habit, theme: Theme) -> some View {
        Button { toggle(habit) } label: {
            HStack(spacing: theme.spacing.s) {
                Image(systemName: isCompleted(habit) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted(habit) ? theme.colors.success : theme.colors.textTertiary)
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(habit.name).font(theme.typography.body).foregroundStyle(theme.colors.textPrimary)
                    if let area = habit.category {
                        Text(area.name).font(theme.typography.caption).foregroundStyle(theme.colors.textSecondary)
                    }
                }
                Spacer()
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(habit.name), \(isCompleted(habit) ? "completed" : "not completed")")
    }

    private func thisWeek(_ weekHabits: [Habit], theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.m) {
            DKSectionHeader("This Week", subtitle: "Flexible goals", theme: theme)
            ForEach(weekHabits) { habit in
                let completed = WeeklyGoalEngine.completedCountThisWeek(habit: habit, entries: entries)
                let target = habit.weeklyTargetCount ?? 1
                DKCard(theme: theme) {
                    HStack(spacing: theme.spacing.m) {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(habit.name).font(theme.typography.headline).foregroundStyle(theme.colors.textPrimary)
                            Text("\(completed) of \(target) this week")
                                .font(theme.typography.body)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        Spacer()
                        Button { toggle(habit) } label: {
                            Image(systemName: isCompleted(habit) ? "checkmark.circle.fill" : "plus.circle")
                                .font(theme.typography.title)
                                .foregroundStyle(isCompleted(habit) ? theme.colors.success : theme.colors.accentPrimary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel("\(isCompleted(habit) ? "Remove today's completion for" : "Complete") \(habit.name)")
                    }
                }
            }
        }
    }

    private func dailyNote(theme: Theme) -> some View {
        DisclosureGroup("A note for today", isExpanded: $noteIsExpanded) {
            TextField("A quiet thought about today", text: Binding(
                get: { todayEntry?.note ?? "" },
                set: updateDailyNote
            ), axis: .vertical)
            .font(theme.typography.body)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(.top, theme.spacing.s)
            .accessibilityLabel("Note for today")
        }
        .font(theme.typography.headline)
        .tint(theme.colors.accentPrimary)
    }

    private func emptyDay(theme: Theme) -> some View {
        DKCard(theme: theme) {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                Text("Nothing planned for today.")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                Text("When you're ready, shape a small rhythm in My Life.")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                NavigationLink("Set up a habit") { DomainFocusPicker() }
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.accentPrimary)
                    .frame(minHeight: 44)
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 0..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private func summary(todayHabits: [Habit], completed: Int) -> String {
        if todayHabits.isEmpty { return "Nothing planned for today." }
        if completed == todayHabits.count { return "You showed up today." }
        if completed == 0, let first = upNext(from: todayHabits) { return "Your day is ready. Start with \(first.name)." }
        return "\(completed) of \(todayHabits.count) done."
    }

    private func upNext(from habits: [Habit]) -> Habit? {
        habits.first(where: \.isPinned) ?? habits.first
    }

    private var todayEntry: DailyEntry? {
        entries.first { Calendar.current.isDateInToday($0.dateKey) }
    }

    private var lastSevenDays: [Date] {
        (0..<7).reversed().compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
    }

    private func state(for habit: Habit, on date: Date = .now) -> HabitState? {
        let entry = entries.first { Calendar.current.isDate($0.dateKey, inSameDayAs: date) }
        return entry?.habitStates.first { $0.habit?.id == habit.id }
    }

    private func isCompleted(_ habit: Habit) -> Bool { state(for: habit)?.isCompleted == true }

    private func toggle(_ habit: Habit) {
        guard let entry = todayEntry else { return }
        let completing = !isCompleted(habit)
        if let state = state(for: habit) {
            state.isCompleted = completing
            state.completedAt = completing ? .now : nil
        } else {
            let state = HabitState(isCompleted: true, completedAt: .now, dailyEntry: entry, habit: habit)
            modelContext.insert(state)
            entry.habitStates.append(state)
            habit.states.append(state)
        }
        do {
            try modelContext.save()
            if completing { completionFeedback += 1 }
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func updateDailyNote(_ note: String) {
        guard let entry = todayEntry else { return }
        entry.note = note
        try? modelContext.save()
    }
}
