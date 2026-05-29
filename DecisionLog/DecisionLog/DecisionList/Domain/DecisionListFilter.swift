import Foundation

/// `.category(_)` is open-ended so adding Relationships / Personal / Other later
/// doesn't require touching this enum.
public enum DecisionListFilter: Equatable, Sendable {
    case all
    case pending
    case done
    case category(DecisionCategory)
}
