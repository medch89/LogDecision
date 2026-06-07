import Foundation

@MainActor
public final class DecisionRowViewModel {
    public let id: UUID
    public let title: HighlightedText
    public let categoryText: String
    public let dueText: String
    public let statusBadgeText: String
    public let badgeColor: BadgeColorToken
    public let canCheckIn: Bool
    public let requiresDeleteConfirmation: Bool
    public let accessibilityLabel: String

    private let decision: Decision
    private let actionHandler: ActionHandler<DecisionListAction>
    private let delete: (UUID) -> Void

    public init(
        decision: Decision,
        now: Date,
        search: String?,
        calendar: Calendar = .current,
        actionHandler: @escaping ActionHandler<DecisionListAction>,
        delete: @escaping (UUID) -> Void
    ) {
        let status = decision.status(now: now, calendar: calendar)
        let category = DecisionRowPresenter.categoryText(decision.category)

        self.id = decision.id
        self.title = DecisionRowPresenter.highlight(decision.title, search: search)
        self.categoryText = category
        self.dueText = DecisionRowPresenter.dueText(for: decision, status: status, calendar: calendar)
        self.statusBadgeText = DecisionRowPresenter.badgeText(status)
        self.badgeColor = DecisionRowPresenter.badgeColor(status)
        self.canCheckIn = DecisionRowPresenter.canCheckIn(status)
        self.requiresDeleteConfirmation = DecisionRowPresenter.isDone(status)
        self.accessibilityLabel = DecisionRowPresenter.accessibilityLabel(
            title: decision.title, category: category, status: status, decision: decision, calendar: calendar
        )

        self.decision = decision
        self.actionHandler = actionHandler
        self.delete = delete
    }

    public func tap() { actionHandler(.select(decision)) }
    public func edit() { actionHandler(.select(decision)) }
    public func checkIn() { actionHandler(.select(decision)) }
    public func requestDelete() { delete(id) }
}
