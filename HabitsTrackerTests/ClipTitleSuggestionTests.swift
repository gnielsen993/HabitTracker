import XCTest
@testable import HabitsTracker

/// Unit tests for `ClipTitleSuggestion` — the D-02 zero-network title-suggestion
/// helper (CLIP-01/CLIP-02). Pure function tests: no SwiftData container, no
/// `@MainActor`, always runnable per §9.7 (mirrors `CollectionRollupEngineTests`).
///
/// Assertions are written as invariants (non-empty, contains-substring,
/// no-hyphen, no-crash) rather than exact full-string equality, so the
/// precise humanization rule stays Claude's Discretion (D-02) while the
/// contract stays enforced.
final class ClipTitleSuggestionTests: XCTestCase {

    // MARK: - Bare host URL

    /// A bare-host URL (no meaningful path) yields a non-empty suggestion
    /// derived from the host — assert non-empty AND contains "example"
    /// (case-insensitive), not a hard-coded full string.
    func testBareHost() {
        let result = ClipTitleSuggestion.suggest(from: "https://example.com")
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.lowercased().contains("example"))
    }

    // MARK: - URL with a slug

    /// A URL with a meaningful last path component yields a humanized slug —
    /// contains "sourdough" (case-insensitive) and no longer contains a hyphen
    /// (hyphens replaced with spaces).
    func testUrlWithSlug() {
        let result = ClipTitleSuggestion.suggest(from: "https://www.nytimes.com/2026/01/how-to-make-sourdough")
        XCTAssertTrue(result.lowercased().contains("sourdough"))
        XCTAssertFalse(result.contains("-"))
    }

    // MARK: - Normal URL

    /// A normal URL (host + slug/path) yields a non-empty readable suggestion.
    func testNormalUrlNonEmpty() {
        let result = ClipTitleSuggestion.suggest(from: "https://tiktok.com/@user/video/123")
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: - Malformed / empty fallback

    /// A malformed/no-scheme garbage string and an empty string both return
    /// gracefully (no crash) with the documented fallback: empty string.
    func testMalformedFallback() {
        let raw = "not a url ::: %%%"
        let malformed = ClipTitleSuggestion.suggest(from: raw)
        // Call returns without trapping; fallback is either empty or the raw trimmed input.
        XCTAssertTrue(malformed.isEmpty || malformed == raw.trimmingCharacters(in: .whitespacesAndNewlines))

        let empty = ClipTitleSuggestion.suggest(from: "")
        XCTAssertEqual(empty, "")
    }
}
