import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import DesignKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var categories: [Domain]
    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]
    @Query(sort: \Rule.createdAt) private var rules: [Rule]
    @Query(sort: \Collection.sortIndex) private var collections: [Collection]
    @Query(sort: \CollectionItem.sortIndex) private var collectionItems: [CollectionItem]
    @Query(sort: \Clip.createdAt) private var clips: [Clip]
    @Query(sort: \Idea.createdAt) private var ideas: [Idea]
    @Query(sort: \HabitScheduleRevision.effectiveDate) private var scheduleRevisions: [HabitScheduleRevision]

    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDocument = BackupJSONDocument()
    @State private var message: String?
    @State private var showingOnboarding = false

    private let exportImportService = ExportImportService()
    private let seedDataService = SeedDataService()

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Mode", selection: $themeManager.mode) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    DKThemePicker(
                        themeManager: themeManager,
                        theme: theme,
                        scheme: colorScheme
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section("Management") {
                    NavigationLink("Manage Areas") {
                        DomainFocusPicker()
                    }
                    NavigationLink("Manage Habits") {
                        HabitManagerView()
                    }
                }

                Section("Help") {
                    Button("Replay Welcome") {
                        showingOnboarding = true
                    }
                }

                Section("Backup") {
                    Button("Export JSON") {
                        do {
                            let data = try exportImportService.exportData(categories: categories, habits: habits, entries: entries, rules: rules, collections: collections, collectionItems: collectionItems, clips: clips, ideas: ideas, scheduleRevisions: scheduleRevisions)
                            exportDocument = BackupJSONDocument(data: data)
                            showingExporter = true
                        } catch {
                            message = "Export failed: \(error.localizedDescription)"
                        }
                    }

                    Button("Import JSON (Replace)", role: .destructive) {
                        showingImporter = true
                    }

                    Button("Restore Defaults") {
                        do {
                            try seedDataService.restoreMissingDefaults(context: modelContext)
                            message = "Defaults restored."
                        } catch {
                            message = "Restore failed: \(error.localizedDescription)"
                        }
                    }
                }

                // Read-only app/data visibility (POL-04 D-13) — surfaces the same
                // source-of-truth schema constant Export/Import uses, never a
                // divergent literal.
                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                    LabeledContent("Data schema", value: "v\(ExportImportService.currentSchemaVersion)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "habittracker-backup"
            ) { result in
                if case .failure(let error) = result {
                    message = "Save failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        let data = try Data(contentsOf: url)
                        try exportImportService.importReplace(data: data, context: modelContext)
                        message = "Import complete."
                    } catch {
                        message = "Import failed: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    message = "Import canceled: \(error.localizedDescription)"
                }
            }
            .alert("Status", isPresented: Binding(get: { message != nil }, set: { _ in message = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(isFirstRun: false) {
                    showingOnboarding = false
                }
            }
        }
    }
}
