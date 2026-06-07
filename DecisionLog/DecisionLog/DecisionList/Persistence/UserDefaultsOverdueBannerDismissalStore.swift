import Foundation

public final class UserDefaultsOverdueBannerDismissalStore: OverdueBannerDismissalStore {
    private let defaults: UserDefaults
    private let key = "overdueBanner.lastDismissed"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func lastDismissed() -> Date? {
        defaults.object(forKey: key) as? Date
    }

    public func setDismissed(_ date: Date) {
        defaults.set(date, forKey: key)
    }
}
