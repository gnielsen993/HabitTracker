import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import DesignKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var categories: [Domain]
    @Query(sort: \Habit.name) private var habits: [Habit]
    @Query(sort: \DailyEntry.dateKey, order: .reverse) private var entries: [DailyEntry]
    @Query(sort: \Rule.createdAt) private var rules: [Rule]
    @Query(sort: \Collection.sortIndex) private var collections: [Collection]
    @Query(sort: \CollectionItem.sortIndex) private var collectionItems: [CollectionItem]

    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDocument = BackupJSONDocument()
    @State private var message: String?

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

                    Picker("Preset", selection: $themeManager.preset) {
                        ForEach(ThemePreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue.capitalized).tag(preset)
                        }
                    }
                }

                Section("Management") {
                    NavigationLink("Manage Domains") {
                        DomainFocusPicker()
                    }
                    NavigationLink("Manage Habits") {
                        HabitManagerView()
                    }
                }

                Section("Backup") {
                    Button("Export JSON") {
                        do {
                            let data = try exportImportService.exportData(categories: categories, habits: habits, entries: entries, rules: rules, collections: collections, collectionItems: collectionItems)
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
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "habittracker-backup-v4"
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
        }
    }
}
