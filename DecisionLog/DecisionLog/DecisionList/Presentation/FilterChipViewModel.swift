import Foundation

@MainActor
public final class FilterChipViewModel: Identifiable {
    public let id: String
    public let title: String
    public let isSelected: Bool

    private let onSelect: () -> Void

    public init(id: String, title: String, isSelected: Bool, onSelect: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    public func tap() { onSelect() }
}
