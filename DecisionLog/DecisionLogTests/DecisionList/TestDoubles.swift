import Foundation
@testable import DecisionLog

// MARK: - Loader

/// In-memory loader. Default behaviour: returns the seeded `decisions` filtered
/// by category / outcome / search via the same logic the SwiftData loader uses,
/// so the ViewModel tests exercise realistic behaviour without SwiftData itself.
actor SpyDecisionListLoader: DecisionListLoader {
    var stored: [Decision]
    var loadCallCount = 0
    var overdueCountCallCount = 0
    var loadError: Error?

    init(stored: [Decision] = []) {
        self.stored = stored
    }

    func setStored(_ decisions: [Decision]) {
        self.stored = decisions
    }

    func setLoadError(_ error: Error?) {
        self.loadError = error
    }

    func load(filter: DecisionListFilter, search: String?) async throws -> [Decision] {
        loadCallCount += 1
        if let loadError { throw loadError }

        var result = stored
        switch filter {
        case .all: break
        case .pending: result = result.filter { $0.outcome == nil }
        case .done:    result = result.filter { $0.outcome != nil }
        case .category(let c): result = result.filter { $0.category == c }
        }
        if let needle = search?.lowercased(), !needle.isEmpty {
            result = result.filter { d in
                d.title.lowercased().contains(needle)
                || (d.context?.lowercased().contains(needle) ?? false)
            }
        }
        return result
    }

    func loadOverdueCount(now: Date) async throws -> Int {
        overdueCountCallCount += 1
        return stored.filter { d in
            d.outcome == nil && d.checkInDate < now
        }.count
    }
}

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
            id: id, title: title, context: context,
            optionsConsidered: [], chosenOption: "", predictedOutcome: "",
            confidenceScore: 5, category: category, tags: [], stakes: .low,
            madeAt: checkInDate.addingTimeInterval(-30 * 86_400),
            checkInDate: checkInDate, outcome: outcome,
            aiReflection: nil, voiceNoteURL: nil
        )
    }

    static func outcome(accuracy: Int = 8) -> DecisionOutcome {
        DecisionOutcome(
            actualOutcome: "happened", accuracyRating: accuracy,
            satisfactionRating: 7, learnings: nil, checkedInAt: Date()
        )
    }
}
