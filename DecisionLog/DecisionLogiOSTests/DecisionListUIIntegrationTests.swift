import  Foundation
import Testing
import DecisionLog
@testable import DecisionLogiOS

@MainActor
@Suite("DecisionList UI integration")
struct DecisionListUIIntegrationTests {

    @Test("init renders no state")
    func init_doesNotRenderAnyState() throws {
        let (sut, _) = makeSUT()

        #expect(try sut.numberOfRows() == 0)
        #expect(try sut.rendersEmptyState() == false)
        #expect(try sut.rendersErrorState() == false)
    }

    @Test("init does not request a load")
    func init_doesNotRequestLoad() {
        let (_, loader) = makeSUT()

        #expect(loader.loadCallCount == 0)
    }

    @Test("appear requests load only once")
    func appear_requestsLoadOnce() async throws {
        let (sut, loader) = makeSUT(decisions: [decision(title: "A")])

        try sut.simulateAppear()
        try sut.simulateAppear()
        try await sut.waitForRows(1)

        #expect(loader.loadCallCount == 1)
    }

    @Test("appear renders a row per loaded decision")
    func appear_rendersRowsForLoadedDecisions() async throws {
        let (sut, _) = makeSUT(decisions: [decision(title: "A"), decision(title: "B")])

        try sut.simulateAppear()
        try await sut.waitForRows(2)

        #expect(try sut.numberOfRows() == 2)
        #expect(try sut.rendersEmptyState() == false)
    }

    @Test("appear renders the empty state when there are no decisions")
    func appear_rendersEmptyStateForNoDecisions() async throws {
        let (sut, _) = makeSUT(decisions: [])

        try sut.simulateAppear()
        try await sut.waitFor { try $0.rendersEmptyState() }

        #expect(try sut.numberOfRows() == 0)
        #expect(try sut.rendersEmptyState())
    }

    @Test("appear renders the error state when loading fails")
    func appear_rendersErrorStateWhenLoadingFails() async throws {
        let (sut, _) = makeSUT(loadError: anyError())

        try sut.simulateAppear()
        try await sut.waitFor { try $0.rendersErrorState() }

        #expect(try sut.rendersErrorState())
        #expect(try sut.numberOfRows() == 0)
    }

    @Test("appear renders the overdue banner when overdue count is positive")
    func appear_rendersOverdueBanner() async throws {
        let overdue = decision(title: "late", checkInDays: -3)
        let (sut, _) = makeSUT(decisions: [overdue], overdueCount: 2)

        try sut.simulateAppear()
        try await sut.waitForRows(1)

        #expect(try sut.rendersBanner())
    }

    @Test("appear hides the overdue banner when there is no overdue")
    func appear_hidesOverdueBanner() async throws {
        let (sut, _) = makeSUT(decisions: [decision(title: "future", checkInDays: 30)], overdueCount: 0)

        try sut.simulateAppear()
        try await sut.waitForRows(1)

        #expect(try sut.rendersBanner() == false)
    }

    // MARK: - Actions

    @Test("tapping a row routes .select with that decision")
    func tapRow_routesSelect() async throws {
        let target = decision(title: "Tap me")
        let spy = ActionSpy()
        let (sut, _) = makeSUT(decisions: [target], onAction: spy.record)

        try sut.simulateAppear()
        try await sut.waitForRows(1)
        try sut.tapFirstRow()

        #expect(spy.actions == [.select(target)])
    }

    @Test("tapping the empty-state button routes .logFirstDecision")
    func tapEmptyButton_routesLogFirst() async throws {
        let spy = ActionSpy()
        let (sut, _) = makeSUT(decisions: [], onAction: spy.record)

        try sut.simulateAppear()
        try await sut.waitFor { try $0.rendersEmptyState() }
        try sut.tapEmptyStateButton()

        #expect(spy.actions == [.logFirstDecision])
    }

    @Test("tapping the overdue banner routes .openOverdueCatchUp")
    func tapBanner_routesCatchUp() async throws {
        let overdue = decision(title: "late", checkInDays: -3)
        let spy = ActionSpy()
        let (sut, _) = makeSUT(decisions: [overdue], overdueCount: 2, onAction: spy.record)

        try sut.simulateAppear()
        try await sut.waitFor { try $0.rendersBanner() }
        try sut.tapBanner()

        #expect(spy.actions == [.openOverdueCatchUp])
    }

    // MARK: - Helpers

    private func makeSUT(
        decisions: [Decision] = [],
        overdueCount: Int = 0,
        loadError: Error? = nil,
        onAction: @escaping (DecisionListAction) -> Void = { _ in }
    ) -> (sut: DecisionListView, loader: LoaderSpy)  {
        let loader = LoaderSpy(decisions: decisions, overdueCount: overdueCount, loadError: loadError)
        let sut = DecisionListUIComposer.compose(
            loader: loader,
            deleter: loader,
            bannerDismissal: BannerDismissalStub(),
            actionHandler: onAction
        )
        return (sut, loader)
    }

    private func decision(title: String, checkInDays: Int = 5) -> Decision {
        Decision(
            id: UUID(), title: title, context: nil,
            optionsConsidered: [], chosenOption: "A", predictedOutcome: "",
            confidenceScore: try! Score(7), category: .career, tags: [], stakes: .medium,
            madeAt: Date(), checkInDate: Date().addingTimeInterval(Double(checkInDays) * 86_400),
            outcome: nil, aiReflection: nil, voiceNoteURL: nil
        )
    }

    private func anyError() -> Error { NSError(domain: "test", code: 0) }
}

// MARK: - Test doubles

private final class LoaderSpy: DecisionListLoader, DecisionDeleter, @unchecked Sendable {
    private(set) var loadCallCount = 0
    private let decisions: [Decision]
    private let overdueCount: Int
    private let loadError: Error?

    init(decisions: [Decision], overdueCount: Int, loadError: Error?) {
        self.decisions = decisions
        self.overdueCount = overdueCount
        self.loadError = loadError
    }

    func load(filter: DecisionListFilter, search: String?) async throws -> [Decision] {
        loadCallCount += 1
        if let loadError { throw loadError }
        return decisions
    }
    func loadOverdueCount(now: Date) async throws -> Int { overdueCount }
    func delete(id: UUID) async throws {}
    func reinsert(_ decision: Decision) async throws {}
}

private final class BannerDismissalStub: OverdueBannerDismissalStore {
    func lastDismissed() -> Date? { nil }
    func setDismissed(_ date: Date) {}
}

private final class ActionSpy {
    private(set) var actions: [DecisionListAction] = []
    func record(_ action: DecisionListAction) { actions.append(action) }
}
