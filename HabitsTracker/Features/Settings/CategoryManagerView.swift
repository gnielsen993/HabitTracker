import SwiftUI
import SwiftData
import DesignKit

struct CategoryManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var categories: [Domain]

    @State private var newName = ""

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        List {
            Section("Add Category") {
                TextField("Name", text: $newName)
                Button("Add") {
                    guard !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    let category = Domain(
                        name: newName,
                        iconName: "square.grid.2x2",
                        colorToken: "forest",
                        sortIndex: (categories.last?.sortIndex ?? -1) + 1
                    )
                    modelContext.insert(category)
                    try? modelContext.save()
                    newName = ""
                }
            }

            Section("Categories") {
                ForEach(categories, id: \.id) { category in
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundStyle(theme.colors.accentPrimary)
                        Text(category.name)
                            .foregroundStyle(theme.colors.textPrimary)
                        Spacer()
                        Text("#\(category.sortIndex)")
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(categories[index])
                    }
                    try? modelContext.save()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.colors.background)
        .navigationTitle("Categories")
    }
}
