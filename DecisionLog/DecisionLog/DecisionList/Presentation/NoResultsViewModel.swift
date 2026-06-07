import Foundation

@MainActor
public final class NoResultsViewModel {
    public let title: String
    public let subtitle: String

    public init(filter: DecisionListFilter, search: String?) {
        if case let .category(category) = filter {
            let name = DecisionRowPresenter.categoryText(category)
            title = .localise(key: "decisionList.noResults.category.title", name.lowercased())
            subtitle = .localise(key: "decisionList.noResults.category.subtitle")
        } else if let search {
            title = .localise(key: "decisionList.noResults.search.title", search)
            subtitle = .localise(key: "decisionList.noResults.search.subtitle")
        } else {
            title = .localise(key: "decisionList.noResults.generic.title")
            subtitle = .localise(key: "decisionList.noResults.generic.subtitle")
        }
    }
}
