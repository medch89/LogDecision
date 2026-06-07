import SwiftUI
import DecisionLog

/// Shown only when a load exceeds the skeleton delay (see the ViewModel).
struct DecisionListSkeletonView: View {
    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 12) {
                    Circle().frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4).frame(height: 12).frame(maxWidth: 180)
                        RoundedRectangle(cornerRadius: 4).frame(height: 10).frame(maxWidth: 120)
                    }
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .redacted(reason: .placeholder)
        .foregroundStyle(DecisionListColor.secondaryText.opacity(0.3))
        .accessibilityHidden(true)
    }
}
