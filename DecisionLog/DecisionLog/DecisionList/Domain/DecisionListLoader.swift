import Foundation

/// `filter` and `search` are call-site parameters so
/// the same loader instance serves every state of the screen.
///
/// `search` is `nil` when the search bar is empty; the loader is expected to
/// match against `title` and `context` (case-insensitive).
///
/// Implementations are async-throws to match the strict-concurrency rule —
/// even the in-memory SwiftData implementation conforms uniformly.
public protocol DecisionListLoader: Sendable {
    func load(filter: DecisionListFilter, search: String?) async throws -> [Decision]

    /// Global count of pending decisions whose `checkInDate` is in the past.
    /// Used for the overdue banner — independent of the active filter, so
    /// switching to "Career" doesn't make the banner disappear.
    func loadOverdueCount(now: Date) async throws -> Int
}
