import Testing
import Foundation
@testable import DecisionLog

@Suite("DecisionEntityMapper")
struct DecisionEntityMapperTests {

    @Test("round-trip: domain → entity → domain preserves every field")
    func roundTrip() {
        let original = Decision(
            id: UUID(),
            title: "Hire the junior dev",
            context: "Q3 expansion planning",
            optionsConsidered: ["Hire senior", "Promote internally", "Defer"],
            chosenOption: "Hire the junior dev",
            predictedOutcome: "Faster shipping by end of Q4",
            confidenceScore: 7,
            category: .career,
            tags: ["hiring", "team"],
            stakes: .high,
            madeAt: Date(timeIntervalSince1970: 1_690_000_000),
            checkInDate: Date(timeIntervalSince1970: 1_700_000_000),
            outcome: DecisionOutcome(
                actualOutcome: "Shipped one week late",
                accuracyRating: 6, satisfactionRating: 7,
                learnings: "Onboarding took longer than planned",
                checkedInAt: Date(timeIntervalSince1970: 1_705_000_000)
            ),
            aiReflection: "Recency bias on prior hiring win.",
            voiceNoteURL: URL(string: "file:///tmp/note.m4a")
        )

        let roundTripped = DecisionEntityMapper.toDomain(
            DecisionEntityMapper.toEntity(original)
        )
        #expect(roundTripped == original)
    }

    @Test("unknown category raw value falls back to .other (forward compatibility)")
    func unknownCategoryFallsBack() {
        let entity = DecisionEntity(
            id: UUID(), title: "x", context: nil,
            optionsConsidered: [], chosenOption: "", predictedOutcome: "",
            confidenceScore: 5,
            categoryRaw: "futureCategoryThatDoesNotExistYet",
            tags: [], stakesRaw: DecisionStakes.low.rawValue,
            madeAt: Date(), checkInDate: Date(),
            outcome: nil, aiReflection: nil, voiceNoteURL: nil
        )
        let mapped = DecisionEntityMapper.toDomain(entity)
        #expect(mapped.category == .other)
    }

    @Test("Unknow decision stakes raw value should fall back to .low option")
    func unknownStakesFallsBackToLow() {
        let entity = DecisionEntity(
            id: UUID(),
            title: "x",
            context: nil,
            optionsConsidered: [],
            chosenOption: "",
            predictedOutcome: "",
            confidenceScore: 5,
            categoryRaw: "someCategory",
            tags: [],
            stakesRaw: "unknownStakesRawValue",
            madeAt: Date(),
            checkInDate: Date(),
            outcome: nil,
            aiReflection: nil,
            voiceNoteURL: nil
        )
        let mapped = DecisionEntityMapper.toDomain(entity)
        #expect(mapped.stakes == .low)
    }
}
