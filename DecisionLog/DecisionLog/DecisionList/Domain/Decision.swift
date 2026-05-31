import Foundation

/// Core domain entity. Immutable value type — all fields are `let`.
public struct Decision: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let context: String?
    public let optionsConsidered: [String]
    public let chosenOption: String
    public let predictedOutcome: String
    public let confidenceScore: Int  // 1...10
    public let category: DecisionCategory
    public let tags: [String]
    public let stakes: DecisionStakes
    public let madeAt: Date
    public let checkInDate: Date
    public let outcome: DecisionOutcome?
    public let aiReflection: String?
    public let voiceNoteURL: URL?

    public init(
        id: UUID,
        title: String,
        context: String?,
        optionsConsidered: [String],
        chosenOption: String,
        predictedOutcome: String,
        confidenceScore: Int,
        category: DecisionCategory,
        tags: [String],
        stakes: DecisionStakes,
        madeAt: Date,
        checkInDate: Date,
        outcome: DecisionOutcome?,
        aiReflection: String?,
        voiceNoteURL: URL?
    ) {
        self.id = id
        self.title = title
        self.context = context
        self.optionsConsidered = optionsConsidered
        self.chosenOption = chosenOption
        self.predictedOutcome = predictedOutcome
        self.confidenceScore = confidenceScore
        self.category = category
        self.tags = tags
        self.stakes = stakes
        self.madeAt = madeAt
        self.checkInDate = checkInDate
        self.outcome = outcome
        self.aiReflection = aiReflection
        self.voiceNoteURL = voiceNoteURL
    }
}
