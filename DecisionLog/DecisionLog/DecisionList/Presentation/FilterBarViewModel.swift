import Foundation

@MainActor
public final class FilterBarViewModel {
    public typealias ChipData = (
        id: String,
        title: String,
        filter: DecisionListFilter
    )
    public var onChipsReset: Observer<Void>?
    public var onUnselectedChipLoaded: Observer<ChipData>?
    public var onSelectedChipLoaded: Observer<ChipData>?

    private var appeared = false
    private var selected: DecisionListFilter = .all
    private let onSelect: (DecisionListFilter) -> Void
    private let options: [ChipData] = [
        (id: "all", title: .localise(key: "decisionList.filter.all"), filter: .all),
        (id: "pending", title: .localise(key: "decisionList.filter.pending"), filter: .pending),
        (id: "done", title: .localise(key: "decisionList.filter.done"), filter: .done),
        (id: "career", title: .localise(key: "category.career"), filter: .category(.career)),
        (id: "finance", title: .localise(key: "category.finance"), filter: .category(.finance)),
        (id: "health", title: .localise(key: "category.health"), filter: .category(.health))
    ]

    public init(onSelect: @escaping (DecisionListFilter) -> Void) {
        self.onSelect = onSelect
    }

    public func onAppear() {
        guard !appeared else { return }
        appeared = true
        renderChips()
    }

    public func select(_ filter: DecisionListFilter) {
        guard filter != selected else { return }
        selected = filter
        onChipsReset?(())
        renderChips()
        onSelect(filter)
    }

    private func renderChips() {
        for chip in options {
            chip.filter == selected ? onSelectedChipLoaded?(chip) : onUnselectedChipLoaded?(chip)
        }
    }
}
