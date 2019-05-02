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

    func collectedInfo<R: CollectingRule>(for rule: R) -> [File: R.FileInfo] {
        return access.sync {
            // swiftlint:disable:next force_cast
            storage[ObjectIdentifier(R.self)] as! [File: R.FileInfo]
        }
    }
}

extension File: Hashable {
    public static func == (lhs: File, rhs: File) -> Bool {
        switch (lhs.path, rhs.path) {
        case let (.some(lhsPath), .some(rhsPath)):
            return lhsPath == rhsPath
        case (.none, .none):
            return lhs.contents == rhs.contents
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path ?? contents)
    }
}
