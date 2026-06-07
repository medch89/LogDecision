import Foundation

/// Overdue (asc by days overdue) → pending → future (asc by check-in)
/// → done (desc by check-in). Never alphabetical. Lives here, not the loader,
/// because status is derived rather than stored.
public enum DecisionListSorter {

    public static func sorted(_ decisions: [Decision], now: Date) -> [Decision] {
        decisions
            .map { ($0, $0.status(now: now)) }
            .sorted { lhs, rhs in
                let (lDecision, lStatus) = lhs
                let (rDecision, rStatus) = rhs

                let lRank = bucket(lStatus)
                let rRank = bucket(rStatus)
                if lRank != rRank { return lRank < rRank }

                switch (lStatus, rStatus) {
                case let (.overdue(lDays), .overdue(rDays)):
                    if lDays != rDays { return lDays < rDays }
                case (.done, .done):
                    if lDecision.checkInDate != rDecision.checkInDate {
                        return lDecision.checkInDate > rDecision.checkInDate
                    }
                default:
                    if lDecision.checkInDate != rDecision.checkInDate {
                        return lDecision.checkInDate < rDecision.checkInDate
                    }
                }

                // id tiebreaker keeps the order deterministic (not alphabetical).
                return lDecision.id.uuidString < rDecision.id.uuidString
            }
            .map(\.0)
    }

    private static func bucket(_ status: DecisionStatus) -> Int {
        switch status {
        case .overdue: return 0
        case .pending: return 1
        case .future:  return 2
        case .done:    return 3
        }
    }
}
