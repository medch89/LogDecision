import SwiftUI
import DecisionLog

public struct DecisionListView: View {
    @Bindable private var store: DecisionListStore
    private let viewModel: DecisionListViewModel

    init(store: DecisionListStore, viewModel: DecisionListViewModel) {
        self.store = store
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                store.banner.map { banner in
                    Section {
                        banner
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                }

                Section {
                    store.filterBar
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                }

                Section {
                    ForEach(store.rows) { $0.view }
                }

                store.empty.map { centeredRow($0) }
                store.noResults.map { centeredRow($0) }
                store.error.map { centeredRow($0) }
            }
            .listStyle(.plain)
            .navigationTitle(String.localise(key: "decisionList.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        String.localise(key: "decisionList.fab.accessibility"),
                        systemImage: "plus",
                        action: viewModel.addDecision
                    )
                }
            }
            .searchable(text: $store.searchText, prompt: Text(String.localise(key: "decisionList.search.prompt")))
            .onChange(of: store.searchText) { _, newValue in viewModel.search(newValue) }
            .safeAreaInset(edge: .bottom) { store.undoToast }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    private func centeredRow<V: View>(_ view: V) -> some View {
        Section {
            view
                .frame(maxWidth: .infinity)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
    }
}
