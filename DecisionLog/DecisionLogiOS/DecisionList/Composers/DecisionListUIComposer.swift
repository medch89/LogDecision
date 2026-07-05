import SwiftUI
import DecisionLog

public enum DecisionListUIComposer {

    @MainActor
    public static func compose(
        loader: DecisionListLoader,
        deleter: DecisionDeleter,
        bannerDismissal: OverdueBannerDismissalStore,
        actionHandler: @escaping ActionHandler<DecisionListAction>,
        now: @escaping () -> Date = Date.init
    ) -> DecisionListView {
        let store = DecisionListStore()

        let viewModel = DecisionListViewModel(
            loader: loader,
            deleter: deleter,
            bannerDismissal: bannerDismissal,
            actionHandler: actionHandler,
            now: now
        )

        viewModel.onLoadingStarted = { [weak store] _ in
            store?.loading = DecisionListSkeletonView()
            clearStates(store)
        }

        store.filterBar = FilterBarUIComposer.compose(onSelect: { [weak viewModel] filter in
            viewModel?.selectFilter(filter)
        })

        viewModel.onLoaded = { [weak store, weak viewModel] loaded in
            guard let store, let viewModel else { return }
            store.loading = nil
            store.empty = nil
            store.noResults = nil
            store.error = nil
            store.banner = loaded.overdueBannerCount.map { count in
                OverdueBannerView(
                    viewModel: OverdueBannerViewModel(count: count),
                    onTap: viewModel.openOverdueCatchUp
                )
            }
            store.rows = loaded.decisions.map { decision in
                adapt(decision, now: now(), search: loaded.search, actionHandler: actionHandler, delete: viewModel.delete)
            }
        }

        viewModel.onEmpty = { [weak store, weak viewModel] _ in
            guard let store, let viewModel else { return }
            store.rows = []
            store.banner = nil
            store.loading = nil
            store.noResults = nil
            store.error = nil
            store.empty = DecisionListEmptyView(onLogFirst: viewModel.logFirstDecision)
        }

        viewModel.onNoResults = { [weak store, weak viewModel] context in
            guard let store, let viewModel else { return }
            store.rows = []
            store.banner = nil
            store.loading = nil
            store.empty = nil
            store.error = nil
            store.noResults = DecisionListNoResultsView(
                viewModel: NoResultsViewModel(filter: context.filter, search: context.search),
                onAdd: viewModel.addDecision
            )
        }

        viewModel.onLoadingFailed = { [weak store, weak viewModel] _ in
            guard let store, let viewModel else { return }
            store.rows = []
            store.banner = nil
            store.loading = nil
            store.empty = nil
            store.noResults = nil
            store.error = DecisionListErrorView(onRetry: viewModel.retry)
        }

        viewModel.onShowUndoToast = { [weak store, weak viewModel] _ in
            guard let store, let viewModel else { return }
            withAnimation { store.undoToast = UndoToastView(onUndo: viewModel.undoDelete) }
            Task { [weak store] in
                try? await Task.sleep(for: .seconds(4))  // undo window
                withAnimation { store?.undoToast = nil }
            }
        }

        return DecisionListView(store: store, viewModel: viewModel)
    }

    @MainActor
    private static func adapt(
        _ decision: Decision,
        now: Date,
        search: String?,
        actionHandler: @escaping ActionHandler<DecisionListAction>,
        delete: @escaping (UUID) -> Void
    ) -> DecisionListStore.RowItem {
        let rowViewModel = DecisionRowViewModel(
            decision: decision,
            now: now,
            search: search,
            actionHandler: actionHandler,
            delete: delete
        )
        let rowStore = DecisionRowStore()
        rowStore.title = rowViewModel.title
        rowStore.subtitle = "\(rowViewModel.categoryText)  ·  \(rowViewModel.dueText)"
        rowStore.badgeText = rowViewModel.statusBadgeText
        rowStore.badgeColor = rowViewModel.badgeColor

        let view = DecisionRowView(store: rowStore, viewModel: rowViewModel)
        return .init(id: rowViewModel.id, view: view)
    }

    @MainActor
    private static func clearStates(_ store: DecisionListStore?) {
        store?.empty = nil
        store?.noResults = nil
        store?.error = nil
    }
}
