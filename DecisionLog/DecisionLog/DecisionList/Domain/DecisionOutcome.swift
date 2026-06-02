import Foundation

public struct DecisionOutcome: Equatable, Sendable {
    public let actualOutcome: String
    public let accuracyRating: Score
    public let satisfactionRating: Score
    public let learnings: String?
    public let checkedInAt: Date

    public init(
        actualOutcome: String,
        accuracyRating: Score,
        satisfactionRating: Score,
        learnings: String?,
        checkedInAt: Date
    ) {
        self.actualOutcome = actualOutcome
        self.accuracyRating = accuracyRating
        self.satisfactionRating = satisfactionRating
        self.learnings = learnings
        self.checkedInAt = checkedInAt
    }
}
