import Foundation

public struct Score: Equatable, Sendable {
    public static let range = 1...10

    public let value: Int

    public enum Error: Swift.Error, Equatable {
        case outOfRange(Int)
    }

    public init(_ value: Int) throws {
        guard Self.range.contains(value) else {
            throw Error.outOfRange(value)
        }
        self.value = value
    }
}
