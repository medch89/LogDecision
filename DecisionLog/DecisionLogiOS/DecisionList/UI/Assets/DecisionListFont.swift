import SwiftUI

/// Per-feature typography tokens (Dynamic Type styles for accessibility sizing).
enum DecisionListFont {
    static let screenTitle = Font.largeTitle.bold()
    static let rowTitle = Font.headline
    static let rowSubtitle = Font.subheadline
    static let badge = Font.caption.weight(.semibold)
    static let bannerTitle = Font.subheadline.weight(.semibold)
    static let bannerSubtitle = Font.caption
    static let emptyTitle = Font.title3.weight(.semibold)
    static let emptyBody = Font.subheadline
    static let filterChip = Font.subheadline.weight(.medium)
}
