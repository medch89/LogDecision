import Foundation

@MainActor
public final class DecisionListViewModel {

    // MARK: Outputs (wired by the Composer)

    public var onLoadingStarted: Observer<Void>?
    public var onLoaded: Observer<LoadedState>?

    public struct LoadedState {
        public let decisions: [Decision]
        public let search: String?
        /// Overdue count to show in the banner; `nil` when the banner is hidden.
        public let overdueBannerCount: Int?
    }

    public var onEmpty: Observer<Void>?
    public var onNoResults: Observer<NoResultsContext>?
    public var onLoadingFailed: Observer<Void>?
    public var onShowUndoToast: Observer<Void>?

    public struct NoResultsContext {
        public let filter: DecisionListFilter
        public let search: String?
    }

    // MARK: Dependencies

    private let loader: DecisionListLoader
    private let deleter: DecisionDeleter
    private let bannerDismissal: OverdueBannerDismissalStore
    private let actionHandler: ActionHandler<DecisionListAction>
    private let now: () -> Date
    private let calendar: Calendar
    private let searchDebounce: Duration
    private let skeletonDelay: Duration

    // MARK: State

    private var filter: DecisionListFilter = .all
    private var searchText: String?
    private var appeared = false

    private var loadTask: Task<Void, Never>?
    private var searchDebounceTask: Task<Void, Never>?
    private var deletedForUndo: Decision?

    public init(
        loader: DecisionListLoader,
        deleter: DecisionDeleter,
        bannerDismissal: OverdueBannerDismissalStore,
        actionHandler: @escaping ActionHandler<DecisionListAction>,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current,
        searchDebounce: Duration = .milliseconds(200),
        skeletonDelay: Duration = .milliseconds(300)
    ) {
        self.loader = loader
        self.deleter = deleter
        self.bannerDismissal = bannerDismissal
        self.actionHandler = actionHandler
        self.now = now
        self.calendar = calendar
        self.searchDebounce = searchDebounce
        self.skeletonDelay = skeletonDelay
    }

    // MARK: Lifecycle

    public func onAppear() {
        guard !appeared else { return }
        appeared = true
        load()
    }

    public func retry() { load() }

    // MARK: Inputs

    public func selectFilter(_ filter: DecisionListFilter) {
        guard filter != self.filter else { return }
        self.filter = filter
        load()
    }

    /// Debounced; empty string restores the full list.
    public func search(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        searchText = trimmed.isEmpty ? nil : trimmed

        searchDebounceTask?.cancel()
        searchDebounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: searchDebounce)
            guard !Task.isCancelled else { return }
            self.load()
        }
    }

    public func dismissOverdueBanner() {
        bannerDismissal.setDismissed(now())
        load()
    }

    // MARK: Actions

    public func addDecision() { actionHandler(.addDecision) }
    public func openOverdueCatchUp() { actionHandler(.openOverdueCatchUp) }
    public func logFirstDecision() { actionHandler(.logFirstDecision) }

    // MARK: Delete + undo

    public func delete(id: UUID) {
        guard let decision = currentDecisions.first(where: { $0.id == id }) else { return }
        deletedForUndo = decision
        Task { [weak self] in
            guard let self else { return }
            do {
                try await deleter.delete(id: id)
                guard !Task.isCancelled else { return }
                self.onShowUndoToast?(())
                self.load()
            } catch {
                self.deletedForUndo = nil
            }
        }
    }

    public func undoDelete() {
        guard let decision = deletedForUndo else { return }
        deletedForUndo = nil
        Task { [weak self] in
            guard let self else { return }
            do {
                try await deleter.reinsert(decision)
                guard !Task.isCancelled else { return }
                self.load()
            } catch { /* nothing to restore */ }
        }
    }

    // MARK: Loading

    private var currentDecisions: [Decision] = []

    private func load() {
        loadTask?.cancel()
        let referenceNow = now()
        let activeFilter = filter
        let activeSearch = searchText

        loadTask = Task { [weak self] in
            guard let self else { return }

            let skeleton = Task { [weak self] in
                try? await Task.sleep(for: self?.skeletonDelay ?? .milliseconds(300))
                guard let self, !Task.isCancelled else { return }
                self.onLoadingStarted?(())
            }

            do {
                async let decisionsAsync = loader.load(filter: activeFilter, search: activeSearch)
                async let overdueAsync = loader.loadOverdueCount(now: referenceNow)
                let (decisions, overdueCount) = try await (decisionsAsync, overdueAsync)
                skeleton.cancel()
                guard !Task.isCancelled else { return }

                self.currentDecisions = decisions
                self.emit(
                    decisions: decisions,
                    overdueCount: overdueCount,
                    now: referenceNow,
                    filter: activeFilter,
                    search: activeSearch
                )
            } catch {
                skeleton.cancel()
                guard !Task.isCancelled else { return }
                self.onLoadingFailed?(())
            }
        }
    }

    private func emit(
        decisions: [Decision],
        overdueCount: Int,
        now: Date,
        filter: DecisionListFilter,
        search: String?
    ) {
        guard !decisions.isEmpty else {
            // Empty-on-first-launch vs. filter/search hid everything: different copy.
            if filter == .all && search == nil {
                onEmpty?(())
            } else {
                onNoResults?(NoResultsContext(filter: filter, search: search))
            }
            return
        }

        let sorted = DecisionListSorter.sorted(decisions, now: now)
        onLoaded?(
            LoadedState(
                decisions: sorted,
                search: search,
                overdueBannerCount: overdueBannerCount(overdueCount: overdueCount, now: now)
            )
        )
    }

    /// Non-nil only when count ≥ 1 and not dismissed within the last 24h.
    private func overdueBannerCount(overdueCount: Int, now: Date) -> Int? {
        guard overdueCount >= 1 else { return nil }
        if let last = bannerDismissal.lastDismissed(),
           now.timeIntervalSince(last) < 24 * 60 * 60 {
            return nil
        }
        return overdueCount
    }

    deinit {
        loadTask?.cancel()
        searchDebounceTask?.cancel()
    }
}
