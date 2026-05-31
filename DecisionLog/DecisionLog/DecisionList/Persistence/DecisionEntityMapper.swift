import Foundation

/// Converts between the SwiftData `@Model` class and the value-type domain `Decision`.
///
/// Lives as an `enum` (no state, no instances) — mirrors the Mapper pattern
/// from the architecture guide for remote loaders.
public enum DecisionEntityMapper {

    // MARK: Entity → Domain

    public static func toDomain(_ entity: DecisionEntity) -> Decision {
        Decision(
            id: entity.id,
            title: entity.title,
            context: entity.context,
            optionsConsidered: entity.optionsConsidered,
            chosenOption: entity.chosenOption,
            predictedOutcome: entity.predictedOutcome,
            confidenceScore: entity.confidenceScore,
            category: DecisionCategory(rawValue: entity.categoryRaw) ?? .other,
            tags: entity.tags,
            stakes: DecisionStakes(rawValue: entity.stakesRaw) ?? .low,
            madeAt: entity.madeAt,
            checkInDate: entity.checkInDate,
            outcome: entity.outcome.map(toDomain),
            aiReflection: entity.aiReflection,
            voiceNoteURL: entity.voiceNoteURL
        )
    }

    public static func toDomain(_ entity: DecisionOutcomeEntity) -> DecisionOutcome {
        DecisionOutcome(
            actualOutcome: entity.actualOutcome,
            accuracyRating: entity.accuracyRating,
            satisfactionRating: entity.satisfactionRating,
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
            confidenceScore: decision.confidenceScore,
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
            accuracyRating: outcome.accuracyRating,
            satisfactionRating: outcome.satisfactionRating,
            learnings: outcome.learnings,
            checkedInAt: outcome.checkedInAt
        )
    }
}
