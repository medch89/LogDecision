import SwiftUI
import DecisionLog

struct DecisionRowView: View {
    private let store: DecisionRowStore
    private let viewModel: DecisionRowViewModel

    init(store: DecisionRowStore, viewModel: DecisionRowViewModel) {
        self.store = store
        self.viewModel = viewModel
    }

    var body: some View {
        Button(action: viewModel.tap) { content }
            .buttonStyle(.plain)
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if viewModel.canCheckIn {
                    Button(action: viewModel.checkIn) {
                        Label(String.localise(key: "decisionList.swipe.checkIn"), systemImage: "checkmark.circle")
                    }
                    .tint(DecisionListColor.badge(.purple))
                    .accessibilityLabel(String.localise(key: "decisionList.swipe.checkIn.accessibility", viewModel.title.text))
                    .accessibilityIdentifier("decisionRow.checkIn")
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: !viewModel.requiresDeleteConfirmation) {
                Button(role: .destructive, action: viewModel.requestDelete) {
                    Label(String.localise(key: "decisionList.swipe.delete"), systemImage: "trash")
                }
                .accessibilityLabel(String.localise(key: "decisionList.swipe.delete.accessibility", viewModel.title.text))
                .accessibilityIdentifier("decisionRow.delete")

                Button(action: viewModel.edit) {
                    Label(String.localise(key: "decisionList.swipe.edit"), systemImage: "pencil")
                }
                .tint(DecisionListColor.badge(.gray))
                .accessibilityLabel(String.localise(key: "decisionList.swipe.edit.accessibility", viewModel.title.text))
                .accessibilityIdentifier("decisionRow.edit")
            }
    }

    private var content: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(DecisionListColor.badge(store.badgeColor))
                .frame(width: 10, height: 10)
                .padding(.top, 5)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HighlightedTextView(model: store.title)
                    .font(DecisionListFont.rowTitle)
                    .foregroundStyle(DecisionListColor.primaryText)

                Text(store.subtitle)
                    .font(DecisionListFont.rowSubtitle)
                    .foregroundStyle(DecisionListColor.secondaryText)
            }

            Spacer(minLength: 8)

            badge
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.accessibilityLabel)
    }

    private var badge: some View {
        Text(store.badgeText)
            .font(DecisionListFont.badge)
            .foregroundStyle(DecisionListColor.badge(store.badgeColor))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(DecisionListColor.badge(store.badgeColor).opacity(0.15)))
    }
}
