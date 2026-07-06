import SwiftUI
import DecisionLog

enum FilterBarUIComposer {

    @MainActor
    static func compose(onSelect: @escaping (DecisionListFilter) -> Void) -> FilterBarView {
        let store = FilterBarStore()
        let viewModel = FilterBarViewModel(onSelect: onSelect)

        viewModel.onChipsReset = { [weak store] _ in
            store?.chips = []
        }

        viewModel.onUnselectedChipLoaded = { [weak store, weak viewModel] chip in
            store?.chips.append(
                makeChip(
                    chip,
                    isSelected: false,
                    background: DecisionListColor.filterChipUnselectedBackground,
                    foreground: DecisionListColor.filterChipUnselectedForeground,
                    select: { [weak viewModel] in viewModel?.select(chip.filter) }
                )
            )
        }

        viewModel.onSelectedChipLoaded = { [weak store, weak viewModel] chip in
            store?.chips.append(
                makeChip(
                    chip,
                    isSelected: true,
                    background: DecisionListColor.filterChipSelectedBackground,
                    foreground: DecisionListColor.filterChipSelectedForeground,
                    select: { [weak viewModel] in viewModel?.select(chip.filter) }
                )
            )
        }

        return FilterBarView(store: store, viewModel: viewModel)
    }

    @MainActor
    private static func makeChip(
        _ data: FilterBarViewModel.ChipData,
        isSelected: Bool,
        background: Color,
        foreground: Color,
        select: @escaping () -> Void
    ) -> FilterBarStore.ChipItem {
        let chipStore = FilterChipStore()
        chipStore.title = data.title
        chipStore.isSelected = isSelected
        chipStore.backgroundColor = background
        chipStore.foregroundColor = foreground

        let chipViewModel = FilterChipViewModel(id: data.id, onSelect: select)
        let view = FilterChipView(store: chipStore, viewModel: chipViewModel)
        return .init(id: data.id, view: view)
    }
}
