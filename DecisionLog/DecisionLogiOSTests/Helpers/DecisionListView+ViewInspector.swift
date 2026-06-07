import Foundation
import ViewInspector
@testable import DecisionLogiOS

@MainActor
extension DecisionListView {
    func simulateAppear() throws {
        try inspect().navigationStack().callOnAppear()
    }

    func numberOfRows() throws -> Int {
        (try? inspect().findAll(DecisionRowView.self).count) ?? 0
    }

    func rendersEmptyState() throws -> Bool {
        (try? inspect().find(DecisionListEmptyView.self)) != nil
    }

    func rendersErrorState() throws -> Bool {
        (try? inspect().find(DecisionListErrorView.self)) != nil
    }

    func rendersBanner() throws -> Bool {
        (try? inspect().find(OverdueBannerView.self)) != nil
    }

    /// Polls the inspected tree until `condition` holds or it times out.
    func waitFor(_ condition: (DecisionListView) throws -> Bool, timeout: TimeInterval = 2) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (try? condition(self)) == true { return }
            try? await Task.sleep(for: .milliseconds(20))
        }
        _ = try condition(self) // final attempt surfaces errors
    }

    func waitForRows(_ count: Int, timeout: TimeInterval = 2) async throws {
        try await waitFor({ try $0.numberOfRows() == count }, timeout: timeout)
    }

    // MARK: - Taps

    func tapFirstRow() throws {
        try inspect().find(DecisionRowView.self).button().tap()
    }

    func tapEmptyStateButton() throws {
        try inspect().find(DecisionListEmptyView.self).find(ViewType.Button.self).tap()
    }

    func tapBanner() throws {
        try inspect().find(OverdueBannerView.self).button().tap()
    }
}
