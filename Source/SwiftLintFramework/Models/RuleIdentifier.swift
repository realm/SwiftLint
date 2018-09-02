public enum RuleIdentifier: Hashable, ExpressibleByStringLiteral {
    case all
    case single(identifier: String)

    private static let allStringRepresentation = "all"

    public var hashValue: Int {
        return stringRepresentation.hashValue
    }

    public var stringRepresentation: String {
        switch self {
        case .all:
            return RuleIdentifier.allStringRepresentation

        case .single(let identifier):
            return identifier
        }
    }

    public init(_ value: String) {
        self = value == RuleIdentifier.allStringRepresentation ? .all : .single(identifier: value)
    }

    public init(stringLiteral value: String) {
        self = RuleIdentifier(value)
    }

    public static func == (lhs: RuleIdentifier, rhs: RuleIdentifier) -> Bool {
        return lhs.stringRepresentation == rhs.stringRepresentation
    }
}
