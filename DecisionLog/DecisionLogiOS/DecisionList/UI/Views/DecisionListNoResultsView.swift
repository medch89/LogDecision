import SwiftUI
import DecisionLog

struct DecisionListNoResultsView: View {
    let viewModel: NoResultsViewModel
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(viewModel.title).font(DecisionListFont.emptyTitle)
            Text(viewModel.subtitle)
                .font(DecisionListFont.emptyBody)
                .foregroundStyle(DecisionListColor.secondaryText)
                .multilineTextAlignment(.center)
            Button(action: onAdd) {
                Label(String.localise(key: "decisionList.noResults.action"), systemImage: "plus")
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
