import Foundation

/// D-02: the zero-network title-suggestion helper for Clips (CLIP-01/CLIP-02).
///
/// A pure, model-free transform (§9.5) — mirrors `CollectionRollupEngine`'s
/// pure-enum shape (`HabitsTracker/Services/CollectionRollupEngine.swift`).
/// Lives in `Utilities/` alongside `AccentTokenColor.swift` (another pure,
/// model-free transform).
///
/// ABSOLUTELY zero network: only `URLComponents`/`String` work, no fetching
/// of any kind — no session-based requests, no remote loads (SC1 / D-01
/// offline gate, T-04-04). On URL entry, `ClipEditorView` (D-09) calls
/// `suggest(from:)` to prefill an *editable* Title field the user can always
/// overwrite.
enum ClipTitleSuggestion {

    /// Derive an editable suggested title from a URL string.
    ///
    /// Derivation order (Claude's Discretion within D-02's pure/zero-network
    /// constraint):
    /// 1. Trim whitespace; empty input → `""` (T-04-03 graceful fallback).
    /// 2. Parse with `URLComponents`. If the trimmed string has no scheme,
    ///    retry the parse with `https://` prepended transiently — parse-local
    ///    only, never mutates the stored `url` (so a bare `example.com` still
    ///    resolves a host).
    /// 3. Prefer the last non-empty path component (slug) when present and
    ///    meaningful: strip a trailing file extension, replace `-`/`_` with
    ///    spaces, collapse whitespace, and capitalize words for readability.
    /// 4. Fall back to the host (dropping a leading `www.`) when there is no
    ///    useful slug.
    /// 5. Malformed/no-scheme garbage that yields neither a host nor a slug
    ///    returns `""` — the editor leaves the Title field empty for the user
    ///    to fill (graceful fallback, T-04-03: no force-unwraps, no crash).
    nonisolated static func suggest(from urlString: String) -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        // Parse-local scheme normalization: never mutates the caller's string.
        let components = URLComponents(string: trimmed)
            ?? (trimmed.contains("://") ? nil : URLComponents(string: "https://" + trimmed))

        guard let components else { return "" }

        // Prefer a meaningful slug from the last non-empty path component.
        let pathComponents = components.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }

        if let slug = pathComponents.last, let humanized = humanize(slug: slug) {
            return humanized
        }

        // Fall back to the host, dropping a leading "www.".
        if let host = components.host, !host.isEmpty {
            return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        }

        return ""
    }

    /// Strip a trailing file extension, replace `-`/`_` with spaces, collapse
    /// whitespace, and title-case the result. Returns `nil` if the slug has
    /// no readable letters/digits left (so the caller falls back to host).
    private nonisolated static func humanize(slug: String) -> String? {
        var stem = slug
        if let dotRange = stem.range(of: ".", options: .backwards), dotRange.lowerBound != stem.startIndex {
            stem = String(stem[stem.startIndex..<dotRange.lowerBound])
        }

        let spaced = stem
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        let collapsed = spaced
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !collapsed.isEmpty else { return nil }

        // Reject slugs with no letters/digits (e.g. a bare "@user" or "123" is
        // still useful, but pure punctuation is not) — extremely defensive,
        // keeps the helper crash-free on any input (T-04-03).
        guard collapsed.rangeOfCharacter(from: .alphanumerics) != nil else { return nil }

        return collapsed
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
