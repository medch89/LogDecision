import DecisionLog

/// Which chips to show is a UI decision, so this lives in the UI layer.
enum FilterChip: CaseIterable, Hashable {
    case all, pending, done, career, finance, health

    var title: String {
        switch self {
        case .all: return .localise(key: "decisionList.filter.all")
        case .pending: return .localise(key: "decisionList.filter.pending")
        case .done: return .localise(key: "decisionList.filter.done")
        case .career: return .localise(key: "category.career")
        case .finance: return .localise(key: "category.finance")
        case .health: return .localise(key: "category.health")
        }
    }

    var filter: DecisionListFilter {
        switch self {
        case .all: return .all
        case .pending: return .pending
        case .done: return .done
        case .career: return .category(.career)
        case .finance: return .category(.finance)
        case .health: return .category(.health)
        }
    }
}
