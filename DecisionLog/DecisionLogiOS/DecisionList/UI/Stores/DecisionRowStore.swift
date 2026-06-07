import SwiftUI
import DecisionLog

@MainActor
@Observable
final class DecisionRowStore {
    var title: HighlightedText = .init(text: "")
    var subtitle: String = ""
    var badgeText: String = ""
    var badgeColor: BadgeColorToken = .gray
}
