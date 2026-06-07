import SwiftUI
import DecisionLog

/// Holds composed view slots; the Composer fills them, the View renders them.
/// No state enum, no branching in the View.
@MainActor
@Observable
final class DecisionListStore {
    var rows: [RowItem] = []
    var banner: OverdueBannerView?
    var loading: DecisionListSkeletonView? = DecisionListSkeletonView()
    var empty: DecisionListEmptyView?
    var noResults: DecisionListNoResultsView?
    var error: DecisionListErrorView?
    var undoToast: UndoToastView?

    var searchText: String = ""
    var selectedFilter: DecisionListFilter = .all

    struct RowItem: Identifiable {
        let id: UUID
        let view: DecisionRowView
    }
}
