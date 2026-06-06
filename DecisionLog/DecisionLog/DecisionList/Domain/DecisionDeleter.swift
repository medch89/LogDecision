import Foundation

public protocol DecisionDeleter: Sendable {
    func delete(id: UUID) async throws
    func reinsert(_ decision: Decision) async throws
}
