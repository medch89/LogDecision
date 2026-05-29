import Foundation

/// The check-in record paired 1-to-1 with a Decision once the user reviews it.
public struct DecisionOutcome: Equatable, Sendable {
    public let actualOutcome: String
    public let accuracyRating: Int     // 1...10
    public let satisfactionRating: Int // 1...10
    public let learnings: String?
    public let checkedInAt: Date

    public init(
        actualOutcome: String,
        accuracyRating: Int,
        satisfactionRating: Int,
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
