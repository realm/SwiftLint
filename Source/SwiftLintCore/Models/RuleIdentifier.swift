/// An identifier representing a SwiftLint rule, or all rules.
public enum RuleIdentifier: Hashable, ExpressibleByStringLiteral {
    // MARK: - Values

    /// Special identifier that should be treated as referring to 'all' SwiftLint rules. One helpful usecase is in
    /// disabling all SwiftLint rules in a given file by adding a `// swiftlint:disable all` comment at the top of the
    /// file.
    case all

    /// Represents a single SwiftLint rule with the specified identifier.
    case single(identifier: String)

    // MARK: - Properties

    private static let allStringRepresentation = "all"

    /// The spelling of the string for this idenfitier.
    public var stringRepresentation: String {
        switch self {
        case .all:
            return Self.allStringRepresentation

        case .single(let identifier):
            return identifier
        }
    }

    // MARK: - Initializers

    /// Creates a `RuleIdentifier` by its string representation.
    ///
    /// - parameter value: The string representation.
    public init(_ value: String) {
        self = value == Self.allStringRepresentation ? .all : .single(identifier: value)
    }

    // MARK: - ExpressibleByStringLiteral Conformance

    public init(stringLiteral value: String) {
        self = Self(value)
    }
}
