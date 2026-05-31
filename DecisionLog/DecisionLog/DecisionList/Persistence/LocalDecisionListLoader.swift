import Foundation
import SwiftData

/// SwiftData-backed implementation of `DecisionListLoader`.
///
/// Uses an `actor` because `ModelContext` is not `Sendable`; isolating all
/// access through a single actor keeps the loader safe to call from any thread
/// while remaining `Sendable` itself.
///
/// Performance: uses `FetchDescriptor.fetchLimit`/`fetchOffset` semantics
/// indirectly — we read the full filtered set and sort/search/filter via the
/// predicate. For S-04 the dataset is per-user (hundreds, not millions); the
/// `batchSize: 20` mentioned in the spec is reserved for a future `loadMore`
/// iteration once the dataset grows.
public actor LocalDecisionListLoader: DecisionListLoader {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func load(filter: DecisionListFilter, search: String?) async throws -> [Decision] {
        let context = ModelContext(container)
        var descriptor = makeDescriptor(filter: filter, search: search)
        descriptor.relationshipKeyPathsForPrefetching = [\.outcome]
        let entities = try context.fetch(descriptor)
        return entities.map(DecisionEntityMapper.toDomain)
    }

    public func loadOverdueCount(now: Date) async throws -> Int {
        let context = ModelContext(container)
        // An overdue decision = no outcome yet AND check-in date is in the past.
        let descriptor = FetchDescriptor<DecisionEntity>(
            predicate: #Predicate { e in
                e.outcome == nil && e.checkInDate < now
            }
        )
        return try context.fetchCount(descriptor)
    }

    // MARK: - Predicate

    /// Build a SwiftData `FetchDescriptor` that filters by chip + search.
    ///
    /// "Done" vs "Pending" can't be expressed in a single predicate (it depends
    /// on `outcome != nil` AND `checkInDate` comparisons); we filter by
    /// outcome-presence in the predicate where possible and post-filter in
    /// Swift for the bits SwiftData can't express.
    private func makeDescriptor(
        filter: DecisionListFilter,
        search: String?
    ) -> FetchDescriptor<DecisionEntity> {
        let trimmedSearch = search?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSearch = !(trimmedSearch?.isEmpty ?? true)
        let needle = trimmedSearch ?? ""

        let predicate: Predicate<DecisionEntity>?
        switch filter {
        case .all:
            predicate = hasSearch
                ? #Predicate { e in
                    e.title.localizedStandardContains(needle)
                    || (e.context.flatMap { $0.localizedStandardContains(needle) } ?? false)
                }
                : nil

        case .pending:
            predicate = hasSearch
                ? #Predicate { e in
                    e.outcome == nil
                    && (e.title.localizedStandardContains(needle)
                        || (e.context ?? "").localizedStandardContains(needle))
                  }
                : #Predicate { e in e.outcome == nil }

        case .done:
            predicate = hasSearch
                ? #Predicate { e in
                    e.outcome != nil
                    && (e.title.localizedStandardContains(needle)
                        || (e.context ?? "").localizedStandardContains(needle))
                  }
                : #Predicate { e in e.outcome != nil }

        case .category(let category):
            let raw = category.rawValue
            predicate = hasSearch
                ? #Predicate { e in
                    e.categoryRaw == raw
                    && (e.title.localizedStandardContains(needle)
                        || (e.context ?? "").localizedStandardContains(needle))
                  }
                : #Predicate { e in e.categoryRaw == raw }
        }

        // Note: sort order is intentionally NOT applied here. The deterministic
        // status-aware sort (overdue → pending → future → done) is computed in
        // the ViewModel, where status is derived. Asking SwiftData to sort by
        // checkInDate alone would give the wrong order for `done` rows.
        return FetchDescriptor<DecisionEntity>(predicate: predicate)
    }
}
