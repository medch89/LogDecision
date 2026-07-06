import SwiftUI

@MainActor
@Observable
final class FilterChipStore {
    var title: String = ""
    var isSelected: Bool = false
    var backgroundColor: Color = DecisionListColor.filterChipUnselectedBackground
    var foregroundColor: Color = DecisionListColor.filterChipUnselectedForeground
}
