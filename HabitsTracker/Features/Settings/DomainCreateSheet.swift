import SwiftUI
import SwiftData
import DesignKit

/// Custom-domain creation sheet (DOM-05 / D-16 / D-17).
///
/// Collects a trimmed name + a curated SF Symbol (`DomainIconPicker`) + one of the five
/// closed accent tokens (`DomainColorSwatchRow`). "Add Domain" is gated on a non-empty
/// trimmed name (validation copy per UI-SPEC). On save it inserts a `Domain` that is
/// focused-by-construction (a domain you deliberately create belongs in your Hub) and
/// non-seeded, mirroring the existing `CategoryManagerView` insert/save pattern.
struct DomainCreateSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    /// Existing domains — used only to compute the next `sortIndex` (parent owns the
    /// catalog query; this is a lightweight read for insertion ordering).
    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    @State private var name = ""
    @State private var iconName = "square.grid.2x2"
    @State private var colorToken = "forest"

    /// The max stored-string name length guard, mirroring CategoryManagerView intent.
    private let maxNameLength = 40

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool { !trimmedName.isEmpty }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .font(theme.typography.body)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > maxNameLength {
                                name = String(newValue.prefix(maxNameLength))
                            }
                        }
                    if !isValid {
                        Text("Give this domain a name to continue.")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                } header: {
                    Text("Name")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Section {
                    DomainIconPicker(selection: $iconName, theme: theme)
                } header: {
                    Text("Icon")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Section {
                    DomainColorSwatchRow(selection: $colorToken, theme: theme, scheme: colorScheme)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } header: {
                    Text("Color")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.colors.background)
            .navigationTitle("New Domain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Domain") { save(theme: theme) }
                        .disabled(!isValid)
                }
            }
        }
    }

    private func save(theme: Theme) {
        guard isValid else { return }
        let domain = Domain(
            name: trimmedName,
            iconName: iconName,
            colorToken: colorToken,
            sortIndex: (domains.last?.sortIndex ?? -1) + 1,
            isSeeded: false,
            seedVersion: 0,
            isFocused: true
        )
        modelContext.insert(domain)
        try? modelContext.save()
        dismiss()
    }
}
