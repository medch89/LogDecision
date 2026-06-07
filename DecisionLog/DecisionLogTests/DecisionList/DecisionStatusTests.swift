import Testing
import Foundation
@testable import DecisionLog

@Suite("Decision.status derivation")
struct DecisionStatusTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)
    private var cal: Calendar { .current }

    @Test("a decision with an outcome is always .done regardless of date")
    func doneWhenOutcomePresent() {
        let d = DecisionFactory.make(
            checkInDate: now.addingTimeInterval(-100 * 86_400), // long overdue date…
            outcome: DecisionFactory.outcome(accuracy: 8)        // …but reviewed
        )
        #expect(d.status(now: now) == .done(.good))
    }

    @Test("past check-in with no outcome is overdue with day count")
    func overdueWithDays() {
        let d = DecisionFactory.make(checkInDate: now.addingTimeInterval(-5 * 86_400))
        #expect(d.status(now: now) == .overdue(daysOverdue: 5))
    }

    @Test("within the 7-day window is pending")
    func pending() {
        let d = DecisionFactory.make(checkInDate: now.addingTimeInterval(3 * 86_400))
        #expect(d.status(now: now) == .pending)
    }

    @Test("beyond the 7-day window is future")
    func future() {
        let d = DecisionFactory.make(checkInDate: now.addingTimeInterval(30 * 86_400))
        #expect(d.status(now: now) == .future)
    }

    @Test("outcome quality buckets on accuracy: good ≥7, poor ≤4, else mixed",
          arguments: [(9, OutcomeQuality.good), (7, .good), (4, .poor), (1, .poor), (5, .mixed), (6, .mixed)])
    func qualityBuckets(_ accuracy: Int, _ expected: OutcomeQuality) {
        let outcome = DecisionFactory.outcome(accuracy: accuracy)
        #expect(outcome.quality == expected)
    }
}
