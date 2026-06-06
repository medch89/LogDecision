import Foundation
import SwiftData

/// `actor` because `ModelContext` is not `Sendable`; routing all access through
/// one actor keeps the loader callable from any thread while staying `Sendable`.
public actor LocalDecisionListLoader: DecisionListLoader, DecisionDeleter {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    // MARK: - DecisionDeleter

    public func delete(id: UUID) async throws {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<DecisionEntity>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entity = try context.fetch(descriptor).first else { return }
        context.delete(entity)
        try context.save()
    }

    public func reinsert(_ decision: Decision) async throws {
        let context = ModelContext(container)
        context.insert(DecisionEntityMapper.toEntity(decision))
        try context.save()
    }

    public func load(filter: DecisionListFilter, search: String?) async throws -> [Decision] {
        let context = ModelContext(container)
        var descriptor = makeDescriptor(filter: filter, search: search)
        descriptor.relationshipKeyPathsForPrefetching = [\.outcome]
        let entities = try context.fetch(descriptor)
        return try entities.map(DecisionEntityMapper.toDomain)
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
                        || (e.context.flatMap { $0.localizedStandardContains(needle) } ?? false))
                  }
                : #Predicate { e in e.outcome == nil }

        case .done:
            predicate = hasSearch
                ? #Predicate { e in
                    e.outcome != nil
                    && (e.title.localizedStandardContains(needle)
                        || (e.context.flatMap { $0.localizedStandardContains(needle) } ?? false))
                  }
                : #Predicate { e in e.outcome != nil }

        case .category(let category):
            let raw = category.rawValue
            predicate = hasSearch
                ? #Predicate { e in
                    e.categoryRaw == raw
                    && (e.title.localizedStandardContains(needle)
                        || (e.context.flatMap { $0.localizedStandardContains(needle) } ?? false))
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
