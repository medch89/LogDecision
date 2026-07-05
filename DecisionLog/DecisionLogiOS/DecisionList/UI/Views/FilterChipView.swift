import SwiftUI
import DecisionLog

struct FilterChipView: View {
    let viewModel: FilterChipViewModel

    var body: some View {
        Button(action: viewModel.tap) {
            Text(viewModel.title)
                .font(DecisionListFont.filterChip)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(
                        viewModel.isSelected
                            ? DecisionListColor.badge(.purple).opacity(0.18)
                            : Color(.secondarySystemBackground)
                    )
                )
                .foregroundStyle(
                    viewModel.isSelected ? DecisionListColor.badge(.purple) : DecisionListColor.primaryText
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(viewModel.isSelected ? .isSelected : [])
    }
}
