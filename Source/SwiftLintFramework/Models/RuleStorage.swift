import Dispatch
import SourceKittenFramework

public class RuleStorage {
    private var storage: [ObjectIdentifier: [File: Any]]
    private let access = DispatchQueue(label: "io.realm.swiftlint.ruleStorageAccess", attributes: .concurrent)

    public init() {
        storage = [:]
    }

    func collect<R: CollectingRule>(info: R.FileInfo, for file: File, in rule: R) {
        let key = ObjectIdentifier(R.self)
        access.sync(flags: .barrier) {
            storage[key, default: [:]][file] = info
        }
    }

    func collectedInfo<R: CollectingRule>(for rule: R) -> [File: R.FileInfo]? {
        return access.sync {
            storage[ObjectIdentifier(R.self)] as? [File: R.FileInfo]
        }
    }
}
