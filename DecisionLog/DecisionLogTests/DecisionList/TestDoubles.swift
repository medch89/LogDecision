import Foundation
@testable import DecisionLog

// MARK: - Factory

enum DecisionFactory {
    static func make(
        id: UUID = UUID(),
        title: String = "Sample decision",
        category: DecisionCategory = .career,
        checkInDate: Date = Date().addingTimeInterval(86_400),
        outcome: DecisionOutcome? = nil,
        context: String? = nil
    ) -> Decision {
        Decision(
            id: id,
            title: title,
            context: context,
            optionsConsidered: [],
            chosenOption: "",
            predictedOutcome: "",
            confidenceScore: try! Score(5),
            category: category,
            tags: [],
            stakes: .low,
            madeAt: checkInDate.addingTimeInterval(-30 * 86_400),
            checkInDate: checkInDate,
            outcome: outcome,
            aiReflection: nil,
            voiceNoteURL: nil
        )
    }

    static func outcome(accuracy: Int = 8) -> DecisionOutcome {
        DecisionOutcome(
            actualOutcome: "happened", accuracyRating: try! Score(accuracy),
            satisfactionRating: try! Score(7), learnings: nil, checkedInAt: Date()
        )
    }
}
