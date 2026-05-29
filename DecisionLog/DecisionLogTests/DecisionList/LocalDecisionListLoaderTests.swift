import Testing
import Foundation
import SwiftData
@testable import DecisionLog

/// Round-trip tests against a real in-memory SwiftData container. These are
/// genuine integration tests — they exercise the predicate logic for filters
/// and search alongside the mapper.
@Suite("LocalDecisionListLoader")
struct LocalDecisionListLoaderTests {

    @Test("load() returns every decision when filter is .all and search is nil")
    func loadAll() async throws {
        let container = try makeContainer()
        try await seed(container, decisions: [
            DecisionFactory.make(title: "A", category: .career),
            DecisionFactory.make(title: "B", category: .finance)
        ])
        let sut = LocalDecisionListLoader(container: container)

        let result = try await sut.load(filter: .all, search: nil)

        #expect(Set(result.map(\.title)) == ["A", "B"])
    }

    @Test("load() returns decision outcome for done decisions")
    func outcomeRoundTrip() async throws {
        let container = try makeContainer()
        try await seed(container, decisions: [
            DecisionFactory.make(title: "done", outcome: DecisionFactory.outcome(accuracy: 8))
        ])
        let sut = LocalDecisionListLoader(container: container)

        let result = try await sut.load(filter: .done, search: nil)
        #expect(result.first?.outcome?.accuracyRating == 8)
    }

    @Test("filter .category narrows to matching category only")
    func filterByCategory() async throws {
        let container = try makeContainer()
        try await seed(container, decisions: [
            DecisionFactory.make(title: "A", category: .career),
            DecisionFactory.make(title: "B", category: .finance)
        ])
        let sut = LocalDecisionListLoader(container: container)

        let result = try await sut.load(filter: .category(.career), search: nil)

        #expect(result.map(\.title) == ["A"])
    }

    @Test("filter .pending excludes decisions with an outcome")
    func filterPending() async throws {
        let container = try makeContainer()
        try await seed(container, decisions: [
            DecisionFactory.make(title: "pending"),
            DecisionFactory.make(title: "done", outcome: DecisionFactory.outcome())
        ])
        let sut = LocalDecisionListLoader(container: container)

        let result = try await sut.load(filter: .pending, search: nil)
        #expect(result.map(\.title) == ["pending"])
    }

    @Test("search matches title (case-insensitive)")
    func searchByTitle() async throws {
        let container = try makeContainer()
        try await seed(container, decisions: [
            DecisionFactory.make(title: "Berlin contract"),
            DecisionFactory.make(title: "Gym membership")
        ])
        let sut = LocalDecisionListLoader(container: container)

        let result = try await sut.load(filter: .all, search: "berlin")
        #expect(result.map(\.title) == ["Berlin contract"])
    }

    @Test("search matches context too, not just title")
    func searchByContext() async throws {
        let container = try makeContainer()
        try await seed(container, decisions: [
            DecisionFactory.make(title: "A", context: "berlin office relocation"),
            DecisionFactory.make(title: "B", context: nil)
        ])
        let sut = LocalDecisionListLoader(container: container)

        let result = try await sut.load(filter: .all, search: "berlin")
        #expect(result.map(\.title) == ["A"])
    }

    @Test("loadOverdueCount counts only pending decisions with past check-in dates")
    func overdueCount() async throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let container = try makeContainer()
        try await seed(container, decisions: [
            // overdue, pending
            DecisionFactory.make(title: "late-1", checkInDate: now.addingTimeInterval(-86_400)),
            DecisionFactory.make(title: "late-2", checkInDate: now.addingTimeInterval(-2 * 86_400)),
            // overdue but done — shouldn't count
            DecisionFactory.make(title: "late-done",
                                 checkInDate: now.addingTimeInterval(-86_400),
                                 outcome: DecisionFactory.outcome()),
            // future
            DecisionFactory.make(title: "future", checkInDate: now.addingTimeInterval(86_400))
        ])
        let sut = LocalDecisionListLoader(container: container)

        let count = try await sut.loadOverdueCount(now: now)
        #expect(count == 2)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: DecisionEntity.self, DecisionOutcomeEntity.self,
            configurations: config
        )
    }

    @MainActor
    private func seed(_ container: ModelContainer, decisions: [Decision]) async throws {
        let context = ModelContext(container)
        for d in decisions {
            context.insert(DecisionEntityMapper.toEntity(d))
        }
        try context.save()
    }
}
