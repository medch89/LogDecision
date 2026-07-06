import Foundation

@MainActor
public final class FilterChipViewModel: Identifiable {
    public let id: String

    private let onSelect: () -> Void

    public init(id: String, onSelect: @escaping () -> Void) {
        self.id = id
        self.onSelect = onSelect
    }

    public func tap() { onSelect() }
}
