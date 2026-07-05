import SwiftUI
import DecisionLog

struct FilterBarView: View {
    private let store: FilterBarStore
    private let viewModel: FilterBarViewModel

    init(store: FilterBarStore, viewModel: FilterBarViewModel) {
        self.store = store
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(store.chips) { $0.view }
            }
        }
        .scrollIndicators(.hidden)
        .onAppear(perform: viewModel.onAppear)
    }
}
