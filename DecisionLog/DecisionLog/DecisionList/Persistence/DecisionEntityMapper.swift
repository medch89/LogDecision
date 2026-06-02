import Foundation

public enum DecisionEntityMapper {

    // MARK: Entity → Domain
    public static func toDomain(_ entity: DecisionEntity) throws -> Decision {
        Decision(
            id: entity.id,
            title: entity.title,
            context: entity.context,
            optionsConsidered: entity.optionsConsidered,
            chosenOption: entity.chosenOption,
            predictedOutcome: entity.predictedOutcome,
            confidenceScore: try Score(entity.confidenceScore),
            category: DecisionCategory(rawValue: entity.categoryRaw) ?? .other,
            tags: entity.tags,
            stakes: DecisionStakes(rawValue: entity.stakesRaw) ?? .low,
            madeAt: entity.madeAt,
            checkInDate: entity.checkInDate,
            outcome: try entity.outcome.map(toDomain),
            aiReflection: entity.aiReflection,
            voiceNoteURL: entity.voiceNoteURL
        )
    }

    /// - Throws: `Score.Error.outOfRange` if a stored rating is outside `1...10`.
    public static func toDomain(_ entity: DecisionOutcomeEntity) throws -> DecisionOutcome {
        DecisionOutcome(
            actualOutcome: entity.actualOutcome,
            accuracyRating: try Score(entity.accuracyRating),
            satisfactionRating: try Score(entity.satisfactionRating),
            learnings: entity.learnings,
            checkedInAt: entity.checkedInAt
        )
    }

    // MARK: Domain → Entity

    public static func toEntity(_ decision: Decision) -> DecisionEntity {
        DecisionEntity(
            id: decision.id,
            title: decision.title,
            context: decision.context,
            optionsConsidered: decision.optionsConsidered,
            chosenOption: decision.chosenOption,
            predictedOutcome: decision.predictedOutcome,
            confidenceScore: decision.confidenceScore.value,
            categoryRaw: decision.category.rawValue,
            tags: decision.tags,
            stakesRaw: decision.stakes.rawValue,
            madeAt: decision.madeAt,
            checkInDate: decision.checkInDate,
            outcome: decision.outcome.map(toEntity),
            aiReflection: decision.aiReflection,
            voiceNoteURL: decision.voiceNoteURL
        )
    }

    public static func toEntity(_ outcome: DecisionOutcome) -> DecisionOutcomeEntity {
        DecisionOutcomeEntity(
            actualOutcome: outcome.actualOutcome,
            accuracyRating: outcome.accuracyRating.value,
            satisfactionRating: outcome.satisfactionRating.value,
            learnings: outcome.learnings,
            checkedInAt: outcome.checkedInAt
        )
    }
}
