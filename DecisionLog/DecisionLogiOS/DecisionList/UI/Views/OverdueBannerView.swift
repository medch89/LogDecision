import SwiftUI
import DecisionLog

struct OverdueBannerView: View {
    let viewModel: OverdueBannerViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(DecisionListColor.badge(.coral))
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.title).font(DecisionListFont.bannerTitle)
                    Text(viewModel.subtitle).font(DecisionListFont.bannerSubtitle)
                        .foregroundStyle(DecisionListColor.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DecisionListColor.secondaryText)
                    .font(.caption)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(DecisionListColor.badge(.coral).opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(String.localise(key: "decisionList.banner.accessibilityHint")))
    }
}
