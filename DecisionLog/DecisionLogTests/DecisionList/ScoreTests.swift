import Testing
@testable import DecisionLog

@Suite("Score")
struct ScoreTests {

    @Test("accepts the inclusive bounds and values in between", arguments: [1, 5, 10])
    func acceptsValidValues(_ value: Int) throws {
        let score = try Score(value)
        #expect(score.value == value)
    }

    @Test("rejects values below the range")
    func rejectsTooLow() {
        #expect(throws: Score.Error.outOfRange(0)) {
            _ = try Score(0)
        }
    }

    @Test("rejects values above the range")
    func rejectsTooHigh() {
        #expect(throws: Score.Error.outOfRange(11)) {
            _ = try Score(11)
        }
    }
}
