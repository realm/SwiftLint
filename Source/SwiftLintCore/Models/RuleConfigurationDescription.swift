import Foundation

/// A type that can be converted into a human-readable representation.
public protocol HumanReadable {
    /// Convert an object to Markdown.
    ///
    /// - Returns: A Markdown string describing the object.
    func markdown() -> String

    /// Convert an object to a single line string.
    ///
    /// - Returns: A "one liner" describing the object.
    func oneLiner() -> String
}

/// Description of a rule configuration.
public struct RuleConfigurationDescription: Equatable {
    fileprivate let options: [RuleConfigurationOption]

    public static func from(configuration: any RuleConfiguration) -> Self {
        // Prefer custom descriptions.
        if let customDescription = configuration.parameterDescription {
            return customDescription
        }
        let options: [RuleConfigurationOption] = Mirror(reflecting: configuration).children
            .compactMap { child -> RuleConfigurationDescription? in
                // Property wrappers have names prefixed by an underscore.
                guard let codingKey = child.label, codingKey.starts(with: "_") else {
                    return nil
                }
                guard let element = child.value as? AnyConfigurationElement else {
                    return nil
                }
                return element.description
            }.flatMap(\.options)
        guard options.isNotEmpty else {
            queuedFatalError(
                "Rule configuration '\(configuration)' does not have any parameters. " +
                "A custom description must be created.")
        }
        return Self(options: options.filter { $0.value != .empty })
    }
}

extension RuleConfigurationDescription: HumanReadable {
    public func oneLiner() -> String {
        options.first == .noOptions ? "" : options.map { $0.oneLiner() }.joined(separator: "; ")
    }

    public func markdown() -> String {
        guard options.isNotEmpty, options.first != .noOptions else {
            return ""
        }
        return """
            <table>
            <thead>
            <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
            \(options.map { $0.markdown() }.joined(separator: "\n"))
            </tbody>
            </table>
            """
    }
}

/// A single option of a `RuleConfigurationDescription`.
public struct RuleConfigurationOption: Equatable {
    /// An option serving as a marker for an empty configuration description.
    public static let noOptions = Self(key: "<nothing>", value: .empty)

    fileprivate let key: String
    fileprivate let value: OptionType
}

extension RuleConfigurationOption: HumanReadable {
    public func markdown() -> String {
        """
        <tr>
        <td>
        \(key)
        </td>
        <td>
        \(value.markdown())
        </td>
        </tr>
        """
    }

    public func oneLiner() -> String {
        "\(key): \(value.oneLiner())"
    }
}

/// Type of an option.
public enum OptionType: Equatable {
    case empty
    case flag(Bool)
    case string(String)
    case symbol(String)
    case integer(Int)
    case float(Double)
    case severity(ViolationSeverity)
    case list([OptionType])
    case nested(RuleConfigurationDescription)
}

extension OptionType: HumanReadable {
    public func markdown() -> String {
        switch self {
        case .empty:
            return ""
        case let .flag(value):
            return String(describing: value)
        case let .string(value):
            return "&quot;" + value + "&quot;"
        case let .symbol(value):
            return value
        case let .integer(value):
            return String(describing: value)
        case let .float(value):
            return String(describing: value)
        case let .severity(value):
            return value.rawValue
        case let .list(options):
            return "[" + options.map { $0.markdown() }.joined(separator: ", ") + "]"
        case let .nested(value):
            return value.markdown()
        }
    }

    public func oneLiner() -> String {
        switch self {
        case .empty:
            return ""
        case let .flag(value):
            return String(describing: value)
        case let .string(value):
            return "\"" + value + "\""
        case let .symbol(value):
            return value
        case let .integer(value):
            return String(describing: value)
        case let .float(value):
            return String(describing: value)
        case let .severity(value):
            return value.rawValue
        case let .list(options):
            return "[" + options.map { $0.oneLiner() }.joined(separator: ", ") + "]"
        case let .nested(value):
            return value.oneLiner()
        }
    }
}

/// A result builder creating configuration descriptions.
@resultBuilder
public struct RuleConfigurationDescriptionBuilder {
    public typealias Description = RuleConfigurationDescription

    public static func buildBlock(_ components: Description...) -> Description {
        Self.buildArray(components)
    }

    public static func buildOptional(_ component: Description?) -> Description {
        component ?? Description(options: [])
    }

    public static func buildEither(first component: Description) -> Description {
        component
    }

    public static func buildEither(second component: Description) -> Description {
        component
    }

    public static func buildExpression(_ expression: RuleConfigurationOption) -> Description {
        Description(options: [expression])
    }

    public static func buildExpression(_ expression: any RuleConfiguration) -> Description {
        Description.from(configuration: expression)
    }

    public static func buildArray(_ components: [Description]) -> Description {
        Description(options: components.flatMap { $0.options })
    }
}

infix operator =>: MultiplicationPrecedence

public extension OptionType {
    /// Operator enabling an easy way to create a configuration option.
    ///
    /// - Parameters:
    ///   - key: Name of the option.
    ///   - value: Value of the option.
    ///
    /// - Returns: A configuration option built up by the given data.
    static func => (key: String, value: OptionType) -> RuleConfigurationOption {
        RuleConfigurationOption(key: key, value: value)
    }

    /// Create an option defined by nested configuration description.
    ///
    /// - Parameters:
    ///   - description: A configuration description buildable by applying the result builder syntax.
    ///
    /// - Returns: A configuration option with a value being another configuration description.
    static func nest(@RuleConfigurationDescriptionBuilder _ description: () -> RuleConfigurationDescription) -> Self {
        .nested(description())
    }
}

protocol AnyConfigurationElement {
    var description: RuleConfigurationDescription { get }
}

public protocol AcceptableByConfigurationElement {
    func asOption() -> OptionType
    func asDescription(with: String) -> RuleConfigurationDescription
}

public extension AcceptableByConfigurationElement {
    func asDescription(with key: String) -> RuleConfigurationDescription {
        RuleConfigurationDescription(options: [key => asOption()])
    }
}

@propertyWrapper
public struct ConfigurationElement<T: AcceptableByConfigurationElement>: AnyConfigurationElement {
    var value: T
    let key: String
    var description: RuleConfigurationDescription

    public var wrappedValue: T {
        get { value }
        set {
            value = newValue
            description = value.asDescription(with: key)
        }
    }

    public init(wrappedValue value: T, _ key: String) {
        self.value = value
        self.key = key
        self.description = value.asDescription(with: key)
    }
}

extension ConfigurationElement: Equatable where T: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.value == rhs.value && lhs.description == rhs.description
    }
}

public extension ConfigurationElement where T: RuleConfiguration {
    /// Constructor for a `ConfigurationElement` without a key.
    ///
    /// Only `RuleConfiguration`s are allowed to have an empty key. The configuration will be inlined into its
    /// parent configuration in this specific case.
    init(wrappedValue value: T) {
        self.init(wrappedValue: value, "")
    }
}

extension Optional: AcceptableByConfigurationElement where Wrapped: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        if let value = self {
            return value.asOption()
        }
        return .empty
    }
}

struct Symbol: Equatable, AcceptableByConfigurationElement {
    let value: String

    func asOption() -> OptionType {
        .symbol(value)
    }
}

extension OptionType: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        self
    }
}

extension Bool: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .flag(self)
    }
}

extension String: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .string(self)
    }
}

extension Array: AcceptableByConfigurationElement where Element: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .list(map { $0.asOption() })
    }
}

extension Set: AcceptableByConfigurationElement where Element: AcceptableByConfigurationElement & Comparable {
    public func asOption() -> OptionType {
        sorted().asOption()
    }
}

extension Int: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .integer(self)
    }
}

extension Double: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .float(self)
    }
}

extension NSRegularExpression: AcceptableByConfigurationElement, Comparable {
    public func asOption() -> OptionType {
        .string(pattern)
    }

    public static func < (lhs: NSRegularExpression, rhs: NSRegularExpression) -> Bool {
        lhs.pattern < rhs.pattern
    }
}

extension ViolationSeverity: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .symbol(rawValue)
    }
}

public extension RuleConfiguration {
    func asOption() -> OptionType {
        .nested(.from(configuration: self))
    }

    func asDescription(with key: String) -> RuleConfigurationDescription {
        if key.isEmpty {
            return .from(configuration: self)
        }
        return RuleConfigurationDescription(options: [key => asOption()])
    }
}

extension SeverityConfiguration: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        severity.asOption()
    }
}
