import SwiftUI
import DecisionLog

struct UndoToastView: View {
    let onUndo: () -> Void

    var body: some View {
        HStack {
            Text(String.localise(key: "decisionList.undo.message")).foregroundStyle(.white)
            Spacer()
            Button(String.localise(key: "decisionList.undo.action"), action: onUndo)
                .foregroundStyle(DecisionListColor.badge(.purple))
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.85)))
        .padding(.horizontal)
    }
}
