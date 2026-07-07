import SwiftUI
import SwiftData
import DesignKit

/// Domain focus picker / catalog (DOM-04 + D-10).
///
/// Lists every domain with a per-row focus `Toggle` bound to `isFocused`. Toggling only
/// flips the flag (saving) — it NEVER deletes the domain or its habits; unfocusing just
/// hides the Hub tile (data persists). Newly merge-added seed domains (isSeeded &&
/// !isFocused && seedVersion == 2) carry an inline "New" `DKBadge`, and when any exist a
/// caption header surfaces the "new domains available" hint (D-10).
///
/// Custom domains (isSeeded == false) support swipe-to-delete behind a confirmation that
/// reassures the user their habits survive (the `.nullify` rule preserves them). A "New
/// Domain" toolbar button presents `DomainCreateSheet`.
struct DomainFocusPicker: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: DKThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Domain.sortIndex) private var domains: [Domain]

    @State private var showingCreate = false
    @State private var pendingDelete: Domain?

    /// The seedVersion that tags merge-added hub domains (from 01-03).
    private let mergeAddedSeedVersion = 2

    private func isNewlyMergeAdded(_ domain: Domain) -> Bool {
        domain.isSeeded && !domain.isFocused && domain.seedVersion == mergeAddedSeedVersion
    }

    private var hasNewDomains: Bool {
        domains.contains(where: isNewlyMergeAdded)
    }

    var body: some View {
        let theme = themeManager.theme(for: colorScheme)

        Group {
            if domains.isEmpty {
                emptyState(theme: theme)
            } else {
                list(theme: theme)
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Domains")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreate = true
                } label: {
                    Label("New Domain", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            DomainCreateSheet()
        }
        .confirmationDialog(
            deleteMessage,
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { confirmDelete() }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
    }

    private var deleteMessage: String {
        guard let name = pendingDelete?.name else { return "" }
        return "Delete '\(name)'? Habits filed here won't be deleted — they'll just lose this domain."
    }

    private func list(theme: Theme) -> some View {
        List {
            if hasNewDomains {
                Section {
                    Text("New domains are available — focus any to add it to your Hub.")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(domains) { domain in
                    row(for: domain, theme: theme)
                        .swipeActions(edge: .trailing) {
                            if !domain.isSeeded {
                                Button(role: .destructive) {
                                    pendingDelete = domain
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func row(for domain: Domain, theme: Theme) -> some View {
        HStack(spacing: theme.spacing.m) {
            Image(systemName: domain.iconName)
                .foregroundStyle(HabitsTracker.accentColor(forToken: domain.colorToken, scheme: colorScheme))
                .frame(minWidth: 28)

            Text(domain.name)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)

            if isNewlyMergeAdded(domain) {
                DKBadge("New", theme: theme)
            }

            Spacer()

            Toggle(
                "Focus \(domain.name)",
                isOn: Binding(
                    get: { domain.isFocused },
                    set: { newValue in
                        domain.isFocused = newValue
                        try? modelContext.save()
                    }
                )
            )
            .labelsHidden()
            .accessibilityLabel("Focus \(domain.name)")
        }
    }

    private func emptyState(theme: Theme) -> some View {
        VStack(spacing: theme.spacing.l) {
            Text("No domains yet")
                .font(theme.typography.titleLarge)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            Text("Create a domain to start filing your lifestyle. Tap New Domain to add one.")
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func confirmDelete() {
        guard let domain = pendingDelete else { return }
        // .nullify delete rule (Domain.habits inverse) preserves the habits — they only
        // lose this domain reference, they are never deleted.
        modelContext.delete(domain)
        try? modelContext.save()
        pendingDelete = nil
    }
}
