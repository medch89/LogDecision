#if DEBUG
import SwiftUI
import DecisionLog

@MainActor
private func previewView(seed: [Decision]) -> some View {
    let stub = PreviewLoaderStub(decisions: seed)
    return DecisionListUIComposer.compose(
        loader: stub,
        deleter: stub,
        bannerDismissal: PreviewBannerDismissal(),
        actionHandler: { _ in }
    )
}

#Preview("Populated") {
    previewView(seed: PreviewSamples.all())
}

#Preview("Empty") {
    previewView(seed: [])
}

/// In-memory loader/deleter for previews — no SwiftData needed.
private actor PreviewLoaderStub: DecisionListLoader, DecisionDeleter {
    private var decisions: [Decision]
    init(decisions: [Decision]) { self.decisions = decisions }

    func load(filter: DecisionListFilter, search: String?) async throws -> [Decision] {
        decisions
    }
    func loadOverdueCount(now: Date) async throws -> Int {
        decisions.filter { $0.outcome == nil && $0.checkInDate < now }.count
    }
    func delete(id: UUID) async throws { decisions.removeAll { $0.id == id } }
    func reinsert(_ decision: Decision) async throws { decisions.append(decision) }
}

private final class PreviewBannerDismissal: OverdueBannerDismissalStore {
    func lastDismissed() -> Date? { nil }
    func setDismissed(_ date: Date) {}
}

/// Self-contained sample data for previews. Kept local to this DEBUG file so the
/// framework ships no seed scaffolding (the app owns its own `DecisionSamples`).
private enum PreviewSamples {
    static func all(now: Date = .init()) -> [Decision] {
        [
            row(now: now, days: -5, title: "Switch project manager", category: .career),
            row(now: now, days: 3, title: "Hire the junior dev", category: .career),
            row(now: now, days: 120, title: "Cancel gym membership", category: .health),
            done(now: now, days: -3, title: "Accept Berlin offer", category: .career, accuracy: 9),
            done(now: now, days: -10, title: "Buy the extended warranty", category: .finance, accuracy: 3),
            done(now: now, days: -20, title: "Take the side contract", category: .finance, accuracy: 5)
        ]
    }

    private static func row(now: Date, days: Int, title: String, category: DecisionCategory) -> Decision {
        make(now: now, title: title, category: category,
             checkIn: now.addingTimeInterval(Double(days) * 86_400), outcome: nil)
    }

    private static func done(now: Date, days: Int, title: String, category: DecisionCategory, accuracy: Int) -> Decision {
        let checkIn = now.addingTimeInterval(Double(days) * 86_400)
        let outcome = DecisionOutcome(
            actualOutcome: "Played out roughly as expected.",
            accuracyRating: (try? Score(accuracy)) ?? score7,
            satisfactionRating: score7,
            learnings: nil,
            checkedInAt: checkIn
        )
        return make(now: now, title: title, category: category, checkIn: checkIn, outcome: outcome)
    }

    private static func make(now: Date, title: String, category: DecisionCategory, checkIn: Date, outcome: DecisionOutcome?) -> Decision {
        Decision(
            id: UUID(), title: title, context: nil,
            optionsConsidered: [], chosenOption: "A", predictedOutcome: "Positive.",
            confidenceScore: score7, category: category, tags: [], stakes: .medium,
            madeAt: checkIn.addingTimeInterval(-30 * 86_400), checkInDate: checkIn,
            outcome: outcome, aiReflection: nil, voiceNoteURL: nil
        )
    }

    private static let score7 = (try? Score(7)) ?? { fatalError("7 is in range") }()
}
#endif
