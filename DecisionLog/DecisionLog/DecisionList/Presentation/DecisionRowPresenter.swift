import Foundation

/// Stateless formatting/colour/accessibility helpers used by the row VM.
enum DecisionRowPresenter {

    static func badgeText(_ status: DecisionStatus) -> String {
        switch status {
        case .overdue: return .localise(key: "decisionList.badge.overdue")
        case .pending: return .localise(key: "decisionList.badge.pending")
        case .future:  return .localise(key: "decisionList.badge.future")
        case .done:    return .localise(key: "decisionList.badge.done")
        }
    }

    static func badgeColor(_ status: DecisionStatus) -> BadgeColorToken {
        switch status {
        case .overdue:            return .coral
        case .pending:            return .purple
        case .future:             return .gray
        case .done(let quality):
            switch quality {
            case .good:  return .teal
            case .poor:  return .coral
            case .mixed: return .amber
            }
        }
    }

    static func canCheckIn(_ status: DecisionStatus) -> Bool {
        switch status {
        case .overdue, .pending: return true
        case .future, .done:     return false
        }
    }

    static func isDone(_ status: DecisionStatus) -> Bool {
        if case .done = status { return true }
        return false
    }

    static func dueText(for decision: Decision, status: DecisionStatus, calendar: Calendar) -> String {
        switch status {
        case .overdue(let days):
            return .localise(key: "decisionList.due.overdue", days)
        case .pending, .future:
            return .localise(key: "decisionList.due.dueDate", mediumDate(decision.checkInDate, calendar: calendar))
        case .done:
            return .localise(key: "decisionList.due.checkedIn")
        }
    }

    static func categoryText(_ category: DecisionCategory) -> String {
        switch category {
        case .career:        return .localise(key: "category.career")
        case .finance:       return .localise(key: "category.finance")
        case .health:        return .localise(key: "category.health")
        case .relationships: return .localise(key: "category.relationships")
        case .personal:      return .localise(key: "category.personal")
        case .other:         return .localise(key: "category.other")
        }
    }

    /// VoiceOver label: "{title}, {category}, {status}, {due}".
    static func accessibilityLabel(
        title: String,
        category: String,
        status: DecisionStatus,
        decision: Decision,
        calendar: Calendar
    ) -> String {
        let statusWord = badgeText(status)
        let due = dueText(for: decision, status: status, calendar: calendar)
        return "\(title), \(category), \(statusWord), \(due)"
    }

    /// Matched ranges (case/diacritic-insensitive) for the View to highlight.
    static func highlight(_ text: String, search: String?) -> HighlightedText {
        guard let needle = search?.trimmingCharacters(in: .whitespacesAndNewlines),
              !needle.isEmpty else {
            return HighlightedText(text: text)
        }

        var ranges: [Range<Int>] = []
        var searchStart = text.startIndex
        while let found = text.range(
            of: needle,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: searchStart..<text.endIndex
        ) {
            let lower = text.distance(from: text.startIndex, to: found.lowerBound)
            let upper = text.distance(from: text.startIndex, to: found.upperBound)
            ranges.append(lower..<upper)
            searchStart = found.upperBound
        }
        return HighlightedText(text: text, highlights: ranges)
    }

    /// "Jun 15" for same-year dates, "Sep 2026" otherwise.
    private static func mediumDate(_ date: Date, calendar: Calendar) -> String {
        let now = Date()
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "MMMd" : "MMMyyyy")
        return formatter.string(from: date)
    }
}
