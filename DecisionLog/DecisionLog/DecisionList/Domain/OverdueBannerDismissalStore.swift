import Foundation

public protocol OverdueBannerDismissalStore {
    func lastDismissed() -> Date?
    func setDismissed(_ date: Date)
}
