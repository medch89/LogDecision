import Testing
import Foundation
@testable import DecisionLog

@Suite("DecisionListSorter")
struct DecisionListSorterTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("orders buckets overdue → pending → future → done")
    func bucketOrder() {
        let done = DecisionFactory.make(title: "done",
                                        checkInDate: now.addingTimeInterval(-2 * 86_400),
                                        outcome: DecisionFactory.outcome())
        let future = DecisionFactory.make(title: "future", checkInDate: now.addingTimeInterval(30 * 86_400))
        let overdue = DecisionFactory.make(title: "overdue", checkInDate: now.addingTimeInterval(-5 * 86_400))
        let pending = DecisionFactory.make(title: "pending", checkInDate: now.addingTimeInterval(2 * 86_400))

        let sorted = DecisionListSorter.sorted([done, future, overdue, pending], now: now)
        #expect(sorted.map(\.title) == ["overdue", "pending", "future", "done"])
    }

    @Test("overdue group ascends by days overdue")
    func overdueAscending() {
        let a = DecisionFactory.make(title: "2d", checkInDate: now.addingTimeInterval(-2 * 86_400))
        let b = DecisionFactory.make(title: "9d", checkInDate: now.addingTimeInterval(-9 * 86_400))
        let c = DecisionFactory.make(title: "5d", checkInDate: now.addingTimeInterval(-5 * 86_400))

        let sorted = DecisionListSorter.sorted([b, c, a], now: now)
        #expect(sorted.map(\.title) == ["2d", "5d", "9d"])
    }

    @Test("done group descends by check-in date (most recent first)")
    func doneDescending() {
        let older = DecisionFactory.make(title: "older",
                                         checkInDate: now.addingTimeInterval(-10 * 86_400),
                                         outcome: DecisionFactory.outcome())
        let newer = DecisionFactory.make(title: "newer",
                                         checkInDate: now.addingTimeInterval(-2 * 86_400),
                                         outcome: DecisionFactory.outcome())
        let sorted = DecisionListSorter.sorted([older, newer], now: now)
        #expect(sorted.map(\.title) == ["newer", "older"])
    }

    @Test("pending/future groups ascend by check-in date")
    func pendingFutureAscending() {
        let soon = DecisionFactory.make(title: "soon", checkInDate: now.addingTimeInterval(1 * 86_400))
        let later = DecisionFactory.make(title: "later", checkInDate: now.addingTimeInterval(40 * 86_400))
        let mid = DecisionFactory.make(title: "mid", checkInDate: now.addingTimeInterval(3 * 86_400))
        let sorted = DecisionListSorter.sorted([later, soon, mid], now: now)
        #expect(sorted.map(\.title) == ["soon", "mid", "later"])
    }
}
