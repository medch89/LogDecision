import Foundation

public enum DecisionStatus: Equatable, Sendable {
    case overdue(daysOverdue: Int)
    case pending
    case future
    case done(OutcomeQuality)
}

public extension Decision {
    func status(
        now: Date,
        calendar: Calendar = .current,
        pendingWindowDays: Int = 7
    ) -> DecisionStatus {
        if let outcome {
            return .done(outcome.quality)
        }
        if checkInDate < now {
            let days = calendar.dateComponents([.day], from: checkInDate, to: now).day ?? 0
            return .overdue(daysOverdue: max(0, days))
        }
        if let window = calendar.date(byAdding: .day, value: pendingWindowDays, to: now),
           checkInDate <= window {
            return .pending
        }
        return .future
    }
}
