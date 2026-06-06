public enum IndentationStyle: Hashable, Sendable {
    case tabs
    case spaces(count: Int)

    package static let `default` = spaces(count: 4)

    public var indentationString: String {
        switch self {
        case .tabs: return "\t"
        case .spaces(let count): return String(repeating: " ", count: count)
        }
    }

    package init?(_ object: Any?) {
        switch object {
        case let value as Int: self = .spaces(count: value)
        case let value as String where value == "tabs": self = .tabs
        default: return nil
        }
    }
}

extension IndentationStyle: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        switch self {
        case .tabs: return .string("tabs")
        case .spaces(let count): return .integer(count)
        }
    }

    public init(fromAny value: Any, context ruleID: String) throws(Issue) {
        switch value {
        case let intValue as Int:
            guard intValue >= 1 else {
                throw Issue.invalidConfiguration(
                    ruleID: ruleID,
                    message: "Option 'indentation' must be a positive integer or the string \"tabs\""
                )
            }
            self = .spaces(count: intValue)
        case let stringValue as String where stringValue == "tabs":
            self = .tabs
        default:
            throw Issue.invalidConfiguration(
                ruleID: ruleID,
                message: "Option 'indentation' must be a positive integer or the string \"tabs\""
            )
        }
    }
}
