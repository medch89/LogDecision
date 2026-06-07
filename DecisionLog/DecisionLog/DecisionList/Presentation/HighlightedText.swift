import Foundation

/// Title plus matched substring ranges (offsets into `text`) for search highlighting.
public struct HighlightedText: Equatable, Sendable {
    public let text: String
    public let highlights: [Range<Int>]

    public init(text: String, highlights: [Range<Int>] = []) {
        self.text = text
        self.highlights = highlights
    }
}
