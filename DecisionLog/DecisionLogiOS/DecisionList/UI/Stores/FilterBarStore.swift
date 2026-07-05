import SwiftUI

@MainActor
@Observable
final class FilterBarStore {
    var chips: [ChipItem] = []

    struct ChipItem: Identifiable {
        let id: String
        let view: FilterChipView
    }
}
