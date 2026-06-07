import SwiftUI
import DecisionLog

struct DecisionListEmptyView: View {
    let onLogFirst: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(DecisionListColor.secondaryText)
            Text(String.localise(key: "decisionList.empty.title"))
                .font(DecisionListFont.emptyTitle)
            Text(String.localise(key: "decisionList.empty.subtitle"))
                .font(DecisionListFont.emptyBody)
                .foregroundStyle(DecisionListColor.secondaryText)
                .multilineTextAlignment(.center)
            Button(String.localise(key: "decisionList.empty.action"), action: onLogFirst)
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
