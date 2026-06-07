import SwiftUI
import DecisionLog

/// Renders a title, colouring the match ranges the ViewModel already decided.
/// Pure rendering — no decisions: it just paints the given ranges.
struct HighlightedTextView: View {
    let model: HighlightedText

    var body: some View {
        Text(attributed)
    }

    private var attributed: AttributedString {
        var result = AttributedString(model.text)
        for range in model.highlights {
            guard let bounds = Range(
                NSRange(location: range.lowerBound, length: range.count),
                in: result
            ) else { continue }
            result[bounds].backgroundColor = DecisionListColor.searchHighlight
        }
        return result
    }
}
