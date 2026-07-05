import Foundation

@MainActor
public final class FilterBarViewModel {
    public typealias ChipData = (
        id: String,
        title: String,
        isSelected: Bool,
        filter: DecisionListFilter
    )
    public var onChipsChanged: Observer<[ChipData]>?

    private var appeared = false
    private var selected: DecisionListFilter = .all
    private let onSelect: (DecisionListFilter) -> Void
    private let options: [(id: String, title: String, filter: DecisionListFilter)] = [
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
        onChipsChanged?(chips())
    }

    public func select(_ filter: DecisionListFilter) {
        guard filter != selected else { return }
        selected = filter
        onChipsChanged?(chips())
        onSelect(filter)
    }

    private func chips() -> [ChipData] {
        options.map { option in
            (id: option.id, title: option.title, isSelected: option.filter == selected, filter: option.filter)
        }
    }
}
