import Foundation

public enum DecisionListAction: Equatable, Sendable {
    case select(Decision)
    case addDecision
    case openOverdueCatchUp
    case logFirstDecision
}
