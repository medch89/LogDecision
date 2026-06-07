import Foundation

public extension String {
    static func localise(key: String) -> String {
        NSLocalizedString(
            key,
            tableName: "DecisionLog",
            bundle: Bundle(for: DecisionLogBundleClass.self),
            comment: ""
        )
    }

    /// Localised format string filled with `arguments` (e.g. counts, dates).
    static func localise(key: String, _ arguments: CVarArg...) -> String {
        String(format: localise(key: key), arguments: arguments)
    }
}
