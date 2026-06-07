import Testing
import Foundation
@testable import DecisionLog

@MainActor
@Suite("DecisionListViewModel")
struct DecisionListViewModelTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeSUT(
        stored: [Decision] = [],
        overdue: Int = 0,
        loadError: Error? = nil,
        lastDismissed: Date? = nil,
        actionHandler: @escaping ActionHandler<DecisionListAction> = { _ in }
    ) -> (DecisionListViewModel, SpyDecisionStore) {
        let store = SpyDecisionStore(stored: stored, overdue: overdue, loadError: loadError)
        let banner = SpyBannerDismissal(last: lastDismissed)
        let sut = DecisionListViewModel(
            loader: store,
            deleter: store,
            bannerDismissal: banner,
            actionHandler: actionHandler,
            now: { self.now },
            searchDebounce: .zero,
            skeletonDelay: .seconds(10)
        )
        return (sut, store)
    }

    /// Captures whichever terminal callback fires first after `trigger`.
    private enum Emission: Equatable {
        case empty
        case noResults(filter: DecisionListFilter, search: String?)
        case failed
        case loaded(bannerCount: Int?, titles: [String])
    }

    private func capture(
        _ sut: DecisionListViewModel,
        afterTriggering trigger: () -> Void
    ) async -> Emission? {
        var captured: Emission?
        sut.onEmpty = { _ in captured = Emission.empty }
        sut.onNoResults = { (context: DecisionListViewModel.NoResultsContext) in
            captured = Emission.noResults(filter: context.filter, search: context.search)
        }
        sut.onLoadingFailed = { _ in captured = Emission.failed }
        sut.onLoaded = { (loaded: DecisionListViewModel.LoadedState) in
            captured = Emission.loaded(bannerCount: loaded.overdueBannerCount, titles: loaded.decisions.map(\.title))
        }
        trigger()
        for _ in 0..<50 where captured == nil {
            try? await Task.sleep(for: .milliseconds(5))
        }
        return captured
    }

    @Test("first launch with no decisions emits onEmpty")
    func emptyOnFirstLaunch() async {
        let (sut, _) = makeSUT(stored: [])
        #expect(await capture(sut) { sut.onAppear() } == .empty)
    }

    @Test("loaded decisions emit sorted rows")
    func loadedRows() async {
        let overdue = DecisionFactory.make(title: "overdue", checkInDate: now.addingTimeInterval(-3 * 86_400))
        let pending = DecisionFactory.make(title: "pending", checkInDate: now.addingTimeInterval(2 * 86_400))
        let (sut, _) = makeSUT(stored: [pending, overdue])

        let emission = await capture(sut) { sut.onAppear() }
        #expect(emission == .loaded(bannerCount: nil, titles: ["overdue", "pending"]))
    }

    @Test("overdue banner shows when count ≥ 1 and not recently dismissed")
    func bannerShown() async {
        let overdue = DecisionFactory.make(checkInDate: now.addingTimeInterval(-3 * 86_400))
        let (sut, _) = makeSUT(stored: [overdue], overdue: 2)

        guard case let .loaded(bannerCount, _) = await capture(sut, afterTriggering: { sut.onAppear() }) else {
            Issue.record("expected loaded"); return
        }
        #expect(bannerCount == 2)
    }

    @Test("overdue banner suppressed when dismissed within 24h")
    func bannerSuppressed() async {
        let overdue = DecisionFactory.make(checkInDate: now.addingTimeInterval(-3 * 86_400))
        let (sut, _) = makeSUT(stored: [overdue], overdue: 2, lastDismissed: now.addingTimeInterval(-3600))

        guard case let .loaded(bannerCount, _) = await capture(sut, afterTriggering: { sut.onAppear() }) else {
            Issue.record("expected loaded"); return
        }
        #expect(bannerCount == nil)
    }

    @Test("load failure emits onLoadingFailed")
    func failure() async {
        struct Boom: Error {}
        let (sut, _) = makeSUT(loadError: Boom())
        #expect(await capture(sut) { sut.onAppear() } == .failed)
    }

    @Test("delete removes the row and offers undo, undo restores it")
    func deleteAndUndo() async {
        let decision = DecisionFactory.make(title: "doomed", checkInDate: now.addingTimeInterval(2 * 86_400))
        let (sut, store) = makeSUT(stored: [decision])
        _ = await capture(sut) { sut.onAppear() }

        var toastShown = false
        sut.onShowUndoToast = { _ in toastShown = true }

        sut.delete(id: decision.id)
        for _ in 0..<50 where !toastShown { try? await Task.sleep(for: .milliseconds(5)) }
        #expect(toastShown)
        #expect(await store.deletedIDs == [decision.id])

        sut.undoDelete()
        for _ in 0..<50 where await store.reinsertedTitles.isEmpty {
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(await store.reinsertedTitles == ["doomed"])
    }
}

actor SpyDecisionStore: DecisionListLoader, DecisionDeleter {
    private var stored: [Decision]
    private let overdue: Int
    private let loadError: Error?
    private(set) var deletedIDs: [UUID] = []
    private(set) var reinsertedTitles: [String] = []

    init(stored: [Decision], overdue: Int, loadError: Error?) {
        self.stored = stored
        self.overdue = overdue
        self.loadError = loadError
    }

    func load(filter: DecisionListFilter, search: String?) async throws -> [Decision] {
        if let loadError { throw loadError }
        var result = stored
        switch filter {
        case .all: break
        case .pending: result = result.filter { $0.outcome == nil }
        case .done: result = result.filter { $0.outcome != nil }
        case .category(let c): result = result.filter { $0.category == c }
        }
        if let needle = search?.lowercased(), !needle.isEmpty {
            result = result.filter {
                $0.title.lowercased().contains(needle)
                || ($0.context?.lowercased().contains(needle) ?? false)
            }
        }
        return result
    }

    func loadOverdueCount(now: Date) async throws -> Int { overdue }

    func delete(id: UUID) async throws {
        deletedIDs.append(id)
        stored.removeAll { $0.id == id }
    }

    func reinsert(_ decision: Decision) async throws {
        reinsertedTitles.append(decision.title)
        stored.append(decision)
    }
}

final class SpyBannerDismissal: OverdueBannerDismissalStore {
    private var last: Date?
    init(last: Date?) { self.last = last }
    func lastDismissed() -> Date? { last }
    func setDismissed(_ date: Date) { last = date }
}
