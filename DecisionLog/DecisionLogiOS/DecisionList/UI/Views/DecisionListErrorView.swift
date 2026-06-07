import SwiftUI
import DecisionLog

struct DecisionListErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(String.localise(key: "decisionList.error.title"), systemImage: "exclamationmark.triangle")
        } actions: {
            Button(String.localise(key: "decisionList.error.retry"), action: onRetry)
        }
    }
}
