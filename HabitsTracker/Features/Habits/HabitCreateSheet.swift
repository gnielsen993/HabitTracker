import SwiftUI
import SwiftData
import DesignKit

/// Source for HabitCreateSheet — drives prefill only; chrome is identical for all cases (D-07).
enum HabitSource {
    case manual
    case rule(Rule)
    case idea(Idea)
}

/// Shared fill-then-commit habit creation sheet (S4, RULE-02).
///
/// Lifecycle: the sheet edits an in-memory draft; the `Habit` is inserted into
/// `modelContext` ONLY on Save (orphan-free cancel — D-04, T-0203-01).
/// Source-agnostic chrome (D-07): identical layout for all launch sources.
/// Prefill: title + domain seeded from the source; both remain editable.
struct HabitCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    let source: HabitSource

    /// Additive, backward-compatible completion invoked once after a successful save
    /// (default nil — existing call sites are unaffected). Lets the promote-to-habit
    /// caller consume the source idea via `PromoteService` (D-07: no backref is set here).
    var onSaved: ((Habit) -> Void)? = nil

    // MARK: - Draft state (in-memory only — NO persisted Habit until Save)

    @State private var title: String = ""
    @State private var selectedDomain: Domain?
    @State private var scheduleType: HabitScheduleType = .daily
    @State private var scheduledDays: [Weekday] = []
    @State private var mode: HabitMode = .required
    @State private var weeklyTargetCount: Int = 1

    // MARK: - Validation

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespaces) }
    private var isSaveEnabled: Bool { !trimmedTitle.isEmpty }

    // MARK: - Init

    init(source: HabitSource = .manual, onSaved: ((Habit) -> Void)? = nil) {
        self.source = source
        self.onSaved = onSaved
    }

    // MARK: - Body

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Form {
                titleSection(theme: theme)
                domainSection(theme: theme)
                modeSection(theme: theme)
                scheduleSection(theme: theme)
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        // Cancel inserts nothing — orphan-free (D-04, T-0203-01)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Habit") {
                        saveHabit(theme: theme)
                    }
                    .foregroundStyle(
                        isSaveEnabled
                            ? theme.colors.accentPrimary
                            : theme.colors.textTertiary
                    )
                    .disabled(!isSaveEnabled)
                }
            }
            .onAppear {
                seedDraftFromSource()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Form Sections

    private func titleSection(theme: Theme) -> some View {
        Section {
            TextField("Habit name", text: $title)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textPrimary)
                .accessibilityLabel("Habit name")
            if !isSaveEnabled && !title.isEmpty {
                Text("Give this a name to continue.")
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }
        } header: {
            Text("Name")
                .font(theme.typography.headline)
        }
    }

    private func domainSection(theme: Theme) -> some View {
        Section {
            Picker("Domain", selection: $selectedDomain) {
                Text("None").tag(Domain?.none)
                ForEach(domains, id: \.id) { domain in
                    Text(domain.name).tag(Domain?.some(domain))
                }
            }
            .foregroundStyle(theme.colors.textPrimary)
        } header: {
            Text("Domain")
                .font(theme.typography.headline)
        }
    }

    private func modeSection(theme: Theme) -> some View {
        Section {
            Picker("Mode", selection: $mode) {
                ForEach(HabitMode.allCases, id: \.self) { m in
                    Text(m.rawValue.capitalized).tag(m)
                }
            }
            .foregroundStyle(theme.colors.textPrimary)

            if mode == .optional {
                Stepper(
                    "Weekly target: \(weeklyTargetCount)",
                    value: $weeklyTargetCount,
                    in: 1...14
                )
                .foregroundStyle(theme.colors.textPrimary)
            }
        } header: {
            Text("Mode")
                .font(theme.typography.headline)
        }
    }

    private func scheduleSection(theme: Theme) -> some View {
        Section {
            Picker("Schedule", selection: $scheduleType) {
                Text("Daily").tag(HabitScheduleType.daily)
                Text("Custom Days").tag(HabitScheduleType.customDays)
            }
            .foregroundStyle(theme.colors.textPrimary)

            if scheduleType == .customDays {
                ForEach(Weekday.allCases, id: \.id) { day in
                    Toggle(day.shortLabel, isOn: Binding(
                        get: { scheduledDays.contains(day) },
                        set: { enabled in
                            var updated = Set(scheduledDays)
                            if enabled { updated.insert(day) } else { updated.remove(day) }
                            scheduledDays = Array(updated).sorted { $0.rawValue < $1.rawValue }
                        }
                    ))
                    .foregroundStyle(theme.colors.textPrimary)
                }
            }
        } header: {
            Text("Schedule")
                .font(theme.typography.headline)
        }
    }

    // MARK: - Prefill from source

    private func seedDraftFromSource() {
        switch source {
        case .manual:
            // No prefill for title; default to first domain if available
            selectedDomain = domains.first
        case .rule(let rule):
            // Prefill title + domain from the rule; both remain editable
            title = rule.title
            selectedDomain = rule.domain
        case .idea(let idea):
            // Prefill title + domain from the idea; both remain editable.
            // No backref is set anywhere (D-07) — the idea-side consume is the
            // promote caller's job via the `onSaved` completion below.
            title = idea.title
            selectedDomain = idea.domain
        }
    }

    // MARK: - Save (single insert point — fill-then-commit, D-04)

    private func saveHabit(theme: Theme) {
        guard isSaveEnabled else { return }

        // Determine originRule — set only when launched from a rule (RULE-03, T-0203-02)
        let originRule: Rule?
        switch source {
        case .manual:
            originRule = nil
        case .rule(let rule):
            originRule = rule
            // Rule is NOT mutated here — stem sets the link only on the Habit side (RULE-03)
        case .idea:
            // No backref from Habit to Idea (D-07) — promote is consume, not a reference.
            originRule = nil
        }

        let weeklyTarget: Int? = mode == .optional ? weeklyTargetCount : nil
        let days: [Weekday] = scheduleType == .customDays ? scheduledDays : []

        // ONLY insert on Save — Cancel exits above without reaching this (D-04, T-0203-01)
        let habit = Habit(
            name: trimmedTitle,
            category: selectedDomain,
            scheduleType: scheduleType,
            scheduledDays: days,
            mode: mode,
            weeklyTargetCount: weeklyTarget,
            originRule: originRule
        )
        modelContext.insert(habit)
        try? modelContext.save()
        onSaved?(habit)
        dismiss()
    }
}
