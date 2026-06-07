import Foundation

@MainActor
public final class OverdueBannerViewModel {
    public let title: String
    public let subtitle: String

    public init(count: Int) {
        self.title = .localise(key: "decisionList.banner.title", count)
        self.subtitle = .localise(key: "decisionList.banner.subtitle")
    }
}
