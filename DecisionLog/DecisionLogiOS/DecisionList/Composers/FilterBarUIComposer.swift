import SwiftUI
import DecisionLog

enum FilterBarUIComposer {

    @MainActor
    static func compose(onSelect: @escaping (DecisionListFilter) -> Void) -> FilterBarView {
        let store = FilterBarStore()
        let viewModel = FilterBarViewModel(onSelect: onSelect)

        viewModel.onChipsChanged = { [weak store, weak viewModel] chipsData in
            store?.chips = chipsData.map { data in
                let chipViewModel = FilterChipViewModel(
                    id: data.id,
                    title: data.title,
                    isSelected: data.isSelected,
                    onSelect: { [weak viewModel] in viewModel?.select(data.filter) }
                )
                return .init(id: data.id, view: FilterChipView(viewModel: chipViewModel))
            }
        }

        return FilterBarView(store: store, viewModel: viewModel)
    }
}
