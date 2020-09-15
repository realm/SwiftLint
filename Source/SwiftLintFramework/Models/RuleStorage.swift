import Dispatch

/// A storage mechanism for aggregating the results of `CollectingRule`s.
public class RuleStorage: CustomStringConvertible {
    private var storage: [ObjectIdentifier: [SwiftLintFile: Any]]
    private let access = DispatchQueue(label: "io.realm.swiftlint.ruleStorageAccess", attributes: .concurrent)

    public var description: String {
        storage.description
    }

    /// Creates a `RuleStorage` with no initial stored data.
    public init() {
        storage = [:]
    }

    /// Collects file info for a given rule into the storage.s
    ///
    /// - parameter info: The file information to store.
    /// - parameter file: The file for which this information pertains to.
    /// - parameter rule: The SwiftLint rule that generated this info.
    func collect<R: CollectingRule>(info: R.FileInfo, for file: SwiftLintFile, in rule: R) {
        let key = ObjectIdentifier(R.self)
        access.sync(flags: .barrier) {
            storage[key, default: [:]][file] = info
        }
    }

    /// Retrieves all file information for a given rule that was collected via `collect(...)`.
    ///
    /// - parameter rule: The rule whose collected information should be retrieved.
    ///
    /// - returns: All file information for a given rule that was collected via `collect(...)`.
    func collectedInfo<R: CollectingRule>(for rule: R) -> [SwiftLintFile: R.FileInfo]? {
        return access.sync {
            storage[ObjectIdentifier(R.self)] as? [SwiftLintFile: R.FileInfo]
        }
    }
}
