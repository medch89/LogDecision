import Foundation
import SwiftData

/// SwiftData persistence model for `Decision`.
///
/// Stored as a class (SwiftData requirement) — it never crosses into the
/// Presentation layer. The mapper converts to/from the value-type `Decision`.
///
/// `categoryRaw` / `stakesRaw` are stored as `String` so we can use SwiftData
/// `#Predicate` filtering by category (predicates need primitive comparisons).
@Model
public final class DecisionEntity {
    #Unique<DecisionEntity>([\.id])
    #Index<DecisionEntity>(
        [\.categoryRaw],
        [\.checkInDate],
        [\.checkInDate, \.outcome]   // compound — matches loadOverdueCount predicate
    )

    public var id: UUID
    public var title: String
    public var context: String?
    public var optionsConsidered: [String]
    public var chosenOption: String
    public var predictedOutcome: String
    public var confidenceScore: Int
    public var categoryRaw: String
    public var tags: [String]
    public var stakesRaw: String
    public var madeAt: Date
    public var checkInDate: Date
    @Relationship(deleteRule: .cascade) public var outcome: DecisionOutcomeEntity?
    public var aiReflection: String?
    public var voiceNoteURL: URL?

    public init(
        id: UUID,
        title: String,
        context: String?,
        optionsConsidered: [String],
        chosenOption: String,
        predictedOutcome: String,
        confidenceScore: Int,
        categoryRaw: String,
        tags: [String],
        stakesRaw: String,
        madeAt: Date,
        checkInDate: Date,
        outcome: DecisionOutcomeEntity?,
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
        self.categoryRaw = categoryRaw
        self.tags = tags
        self.stakesRaw = stakesRaw
        self.madeAt = madeAt
        self.checkInDate = checkInDate
        self.outcome = outcome
        self.aiReflection = aiReflection
        self.voiceNoteURL = voiceNoteURL
    }
}
