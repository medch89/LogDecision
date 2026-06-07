import Foundation

public enum OutcomeQuality: Equatable, Sendable {
    case good
    case poor
    case mixed
}

public extension DecisionOutcome {
    /// good ≥ 7, poor ≤ 4, else mixed.
    var quality: OutcomeQuality {
        switch accuracyRating.value {
        case 7...: return .good
        case ...4: return .poor
        default:   return .mixed
        }
    }
}
