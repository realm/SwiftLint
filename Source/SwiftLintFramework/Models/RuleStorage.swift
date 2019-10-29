import Dispatch
import SourceKittenFramework

public class RuleStorage {
    private var storage: [ObjectIdentifier: [SwiftLintFile: Any]]
    private let access = DispatchQueue(label: "io.realm.swiftlint.ruleStorageAccess", attributes: .concurrent)

    public init() {
        storage = [:]
    }

    func collect<R: CollectingRule>(info: R.FileInfo, for file: SwiftLintFile, in rule: R) {
        let key = ObjectIdentifier(R.self)
        access.sync(flags: .barrier) {
            storage[key, default: [:]][file] = info
        }
    }

    func collectedInfo<R: CollectingRule>(for rule: R) -> [SwiftLintFile: R.FileInfo]? {
        return access.sync {
            storage[ObjectIdentifier(R.self)] as? [SwiftLintFile: R.FileInfo]
        }
    }
}
