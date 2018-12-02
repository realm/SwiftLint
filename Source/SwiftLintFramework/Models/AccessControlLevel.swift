public enum AccessControlLevel: String, CustomStringConvertible {
    case `private` = "source.lang.swift.accessibility.private"
    case `fileprivate` = "source.lang.swift.accessibility.fileprivate"
    case `internal` = "source.lang.swift.accessibility.internal"
    case `public` = "source.lang.swift.accessibility.public"
    case `open` = "source.lang.swift.accessibility.open"

    internal init?(description value: String) {
        switch value {
        case "private": self = .private
        case "fileprivate": self = .fileprivate
        case "internal": self = .internal
        case "public": self = .public
        case "open": self = .open
        default: return nil
        }
    }

    init?(identifier value: String) {
        self.init(rawValue: value)
    }

    public var description: String {
        switch self {
        case .private: return "private"
        case .fileprivate: return "fileprivate"
        case .internal: return "internal"
        case .public: return "public"
        case .open: return "open"
        }
    }

    // Returns true if is `private` or `fileprivate`
    var isPrivate: Bool {
        return self == .private || self == .fileprivate
    }
}

extension AccessControlLevel: Comparable {
    private var priority: Int {
        switch self {
        case .private: return 1
        case .fileprivate: return 2
        case .internal: return 3
        case .public: return 4
        case .open: return 5
        }
    }

    public static func < (lhs: AccessControlLevel, rhs: AccessControlLevel) -> Bool {
        return lhs.priority < rhs.priority
    }
}
