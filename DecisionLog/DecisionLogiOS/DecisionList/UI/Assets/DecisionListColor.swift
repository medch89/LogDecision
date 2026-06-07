import SwiftUI
import DecisionLog

/// Per-feature colour tokens; badge colours come from `Assets.xcassets`
/// (light + dark variants) via generated symbols.
enum DecisionListColor {
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let background = Color(.systemBackground)
    static let rowSeparator = Color(.separator)
    static let searchHighlight = Color(.badgePurple).opacity(0.25)

    static func badge(_ token: BadgeColorToken) -> Color {
        switch token {
        case .coral:  return Color(.badgeCoral)
        case .purple: return Color(.badgePurple)
        case .gray:   return Color(.badgeGray)
        case .teal:   return Color(.badgeTeal)
        case .amber:  return Color(.badgeAmber)
        @unknown default: return Color(.badgeGray)
        }
    }
}
