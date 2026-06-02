import Foundation
import SwiftData

/// SwiftData persistence model for `DecisionOutcome`.
/// Kept as a separate class so SwiftData can manage the 1-to-1 relationship.
@Model
public final class DecisionOutcomeEntity {
    public var actualOutcome: String
    public var accuracyRating: Int
    public var satisfactionRating: Int
    public var learnings: String?
    public var checkedInAt: Date

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
