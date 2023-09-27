import Foundation

// swiftlint:disable file_length

/// A type that can be converted into a human-readable representation.
public protocol Documentable {
    /// Convert an object to Markdown.
    ///
    /// - Returns: A Markdown string describing the object.
    func markdown() -> String

    /// Convert an object to a single line string.
    ///
    /// - Returns: A "one liner" describing the object.
    func oneLiner() -> String

    /// Indicate if the item has some content that is useful to document.
    var hasContent: Bool { get }

    /// Convert an object to YAML as used in `.swiftlint.yml`.
    ///
    /// - Returns: A YAML snippet that can be used in configuration files.
    func yaml() -> String
}

/// Description of a rule configuration.
public struct RuleConfigurationDescription: Equatable {
    fileprivate let options: [RuleConfigurationOption]

    fileprivate init(options: [RuleConfigurationOption]) {
        if options.contains(.noOptions) {
            if options.count > 1 {
                queuedFatalError(
                    """
                    Cannot create a configuration description with a mixture of `noOption`
                    and other options or multiple `noOptions`s. If any, descriptions must only
                    contain one single no-documentation marker.
                    """
                )
            }
            self.options = []
        } else {
            self.options = options.filter { $0.value != .empty }
        }
    }

    static func from(configuration: some RuleConfiguration) -> Self {
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
                """
                Rule configuration '\(configuration)' does not have any parameters.
                A custom description must be provided. If really no documentation is
                required, define the description as `{ RuleConfigurationOption.noOptions }`.
                """
            )
        }
        return Self(options: options)
    }
}

extension RuleConfigurationDescription: Documentable {
    public var hasContent: Bool {
        options.isNotEmpty
    }

    public func oneLiner() -> String {
        oneLiner(separator: ";")
    }

    fileprivate func oneLiner(separator: String) -> String {
        options.map { $0.oneLiner() }.joined(separator: "\(separator) ")
    }

    public func markdown() -> String {
        guard hasContent else {
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

    public func yaml() -> String {
        options.map { $0.yaml() }.joined(separator: "\n")
    }
}

/// A single option of a ``RuleConfigurationDescription``.
public struct RuleConfigurationOption: Equatable {
    /// An option serving as a marker for an empty configuration description.
    public static let noOptions = Self(key: "<nothing>", value: .empty)

    fileprivate let key: String
    fileprivate let value: OptionType
}

extension RuleConfigurationOption: Documentable {
    public var hasContent: Bool {
        self != .noOptions
    }

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

    public func yaml() -> String {
        if case .nested = value {
            return """
                \(key):
                \(value.yaml().indent(by: 2))
                """
        }
        return "\(key): \(value.yaml())"
    }
}

/// Type of an option.
public enum OptionType: Equatable {
    /// An irrelevant option. It will be ignored in documentation serialization.
    case empty
    /// A boolean flag.
    case flag(Bool)
    /// A string option.
    case string(String)
    /// Like a string option but without quotes in the serialized output.
    case symbol(String)
    /// An integer option.
    case integer(Int)
    /// A floating point number option.
    case float(Double)
    /// Special option for a ``ViolationSeverity``.
    case severity(ViolationSeverity)
    /// A list of options.
    case list([OptionType])
    /// An option which is another set of configuration options to be nested in the serialized output.
    case nested(RuleConfigurationDescription)
}

extension OptionType: Documentable {
    public var hasContent: Bool {
        self != .empty
    }

    public func markdown() -> String {
        switch self {
        case .empty, .flag, .symbol, .integer, .float, .severity:
            return yaml()
        case let .string(value):
            return "&quot;" + value + "&quot;"
        case let .list(options):
            return "[" + options.map { $0.markdown() }.joined(separator: ", ") + "]"
        case let .nested(value):
            return value.markdown()
        }
    }

    public func oneLiner() -> String {
        if case let .nested(value) = self {
            return value.oneLiner(separator: ",")
        }
        return yaml()
    }

    public func yaml() -> String {
        switch self {
        case .empty:
            queuedFatalError("Empty options shall not be serialized.")
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
            return value.yaml()
        }
    }
}

// MARK: Result builder

/// A result builder creating configuration descriptions.
@resultBuilder
public struct RuleConfigurationDescriptionBuilder {
    /// :nodoc:
    public typealias Description = RuleConfigurationDescription

    /// :nodoc:
    public static func buildBlock(_ components: Description...) -> Description {
        Self.buildArray(components)
    }

    /// :nodoc:
    public static func buildOptional(_ component: Description?) -> Description {
        component ?? Description(options: [])
    }

    /// :nodoc:
    public static func buildEither(first component: Description) -> Description {
        component
    }

    /// :nodoc:
    public static func buildEither(second component: Description) -> Description {
        component
    }

    /// :nodoc:
    public static func buildExpression(_ expression: RuleConfigurationOption) -> Description {
        Description(options: [expression])
    }

    /// :nodoc:
    public static func buildExpression(_ expression: any RuleConfiguration) -> Description {
        Description.from(configuration: expression)
    }

    /// :nodoc:
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
    /// - Parameter description: A configuration description buildable by applying the result builder syntax.
    ///
    /// - Returns: A configuration option with a value being another configuration description.
    static func nest(@RuleConfigurationDescriptionBuilder _ description: () -> RuleConfigurationDescription) -> Self {
        .nested(description())
    }
}

// MARK: Property wrapper

/// Type of a configuration parameter wrapper.
private protocol AnyConfigurationElement {
    var description: RuleConfigurationDescription { get }
}

/// Type of an object that can be used as a configuration element.
public protocol AcceptableByConfigurationElement {
    /// Initializer taking a value from a configuration to create an element of `Self`.
    ///
    ///   - Parameter value: Value from a configuration.
    ///   - Parameter ruleID: The rule's identifier in which context the configuration parsing runs.
    init(fromAny value: Any, context ruleID: String) throws

    /// Make the object an option.
    ///
    /// - Returns: Option representing the object.
    func asOption() -> OptionType

    /// Make the object a description.
    ///
    /// - Parameter key: Name of the option to be put into the description.
    ///
    /// - Returns: Configuration description of this object.
    func asDescription(with key: String) -> RuleConfigurationDescription

    /// Update the object.
    /// 
    /// - Parameter value: New underlying data for the object.
    mutating func apply(_ value: Any?, ruleID: String) throws
}

/// Default implementations which are shortcuts applicable for most of the types conforming to the protocol.
public extension AcceptableByConfigurationElement {
    func asDescription(with key: String) -> RuleConfigurationDescription {
        RuleConfigurationDescription(options: [key => asOption()])
    }

    mutating func apply(_ value: Any?, ruleID: String) throws {
        if let value {
            self = try Self(fromAny: value, context: ruleID)
        }
    }
}

/// An option type that does not need a key when used in a ``ConfigurationElement``. Its value will be inlined.
public protocol InlinableOptionType: AcceptableByConfigurationElement {}

/// A single parameter of a rule configuration.
///
/// Apply it to a simple (e.g. boolean) property like
/// ```swift
/// @ConfigurationElement(key: "name")
/// var property = true
/// ```
/// If the wrapped element is an ``InlinableOptionType``, there are two options for its representation
/// in the documentation:
///
/// 1. It can be inlined into the parent configuration. For that, do not provide a name as an argument. E.g.
///    ```swift
///    @ConfigurationElement(key: "name")
///    var property = true
///    @ConfigurationElement
///    var levels = SeverityLevelsConfiguration(warning: 1, error: 2)
///    ```
///    will be documented as a linear list:
///    ```
///    name: true
///    warning: 1
///    error: 2
///    ```
/// 2. It can be represented as a separate nested configuration. In this case, it must have a name. E.g.
///    ```swift
///    @ConfigurationElement(key: "name")
///    var property = true
///    @ConfigurationElement(key: "levels")
///    var levels = SeverityLevelsConfiguration(warning: 1, error: 2)
///    ```
///    will have a nested configuration section:
///    ```
///    name: true
///    levels: warning: 1
///            error: 2
///    ```
@propertyWrapper
public struct ConfigurationElement<T: AcceptableByConfigurationElement & Equatable>: Equatable {
    /// Wrapped option value.
    public var wrappedValue: T

    /// The option's name. This field can only be accessed by the element's name prefixed with a `$`.
    public var projectedValue: String { key }

    private let key: String

    /// Default constructor.
    ///
    /// - Parameters:
    ///   - value: Value to be wrapped.
    ///   - key: Name of the option.
    public init(wrappedValue value: T, key: String) {
        self.wrappedValue = value
        self.key = key
    }

    /// Constructor for optional values.
    ///
    /// It allows to skip explicit initialization with `nil` of the property.
    ///
    /// - Parameter value: Value to be wrapped.
    public init<Wrapped>(key: String) where T == Wrapped? {
        self.init(wrappedValue: nil, key: key)
    }

    /// Constructor for a ``ConfigurationElement`` without a key.
    ///
    /// ``InlinableOptionType``s are allowed to have an empty key. The configuration will be inlined into its
    /// parent configuration in this specific case.
    ///
    /// - Parameter value: Value to be wrapped.
    public init(wrappedValue value: T) where T: InlinableOptionType {
        self.init(wrappedValue: value, key: "")
    }
}

extension ConfigurationElement: AnyConfigurationElement {
    fileprivate var description: RuleConfigurationDescription {
        wrappedValue.asDescription(with: key)
    }
}

// MARK: AcceptableByConfigurationElement conformances

extension Optional: AcceptableByConfigurationElement where Wrapped: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        if let value = self {
            return value.asOption()
        }
        return .empty
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? Self else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self = value
    }
}

struct Symbol: Equatable, AcceptableByConfigurationElement {
    let value: String

    func asOption() -> OptionType {
        .symbol(value)
    }

    init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? String else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self.value = value
    }
}

extension Bool: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .flag(self)
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? Self else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self = value
    }
}

extension String: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .string(self)
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? Self else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self = value
    }
}

extension Array: AcceptableByConfigurationElement where Element: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .list(map { $0.asOption() })
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        let values = value as? [Any] ?? [value]
        self = try values.map { try Element(fromAny: $0, context: ruleID) }
    }
}

extension Set: AcceptableByConfigurationElement where Element: AcceptableByConfigurationElement & Comparable {
    public func asOption() -> OptionType {
        sorted().asOption()
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        self = Set(try [Element].init(fromAny: value, context: ruleID))
    }
}

extension Int: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .integer(self)
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? Self else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self = value
    }
}

extension Double: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .float(self)
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? Self else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self = value
    }
}

extension RegularExpression: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .string(pattern)
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        guard let value = value as? String else {
            throw Issue.invalidConfiguration(ruleID: ruleID)
        }
        self = try Self(pattern: value)
    }
}

extension Range: AcceptableByConfigurationElement {
    public func asOption() -> OptionType {
        .symbol("\(lowerBound) ..< \(upperBound)")
    }

    public init(fromAny value: Any, context ruleID: String) throws {
        throw Issue.genericError("Configuration for \(ruleID) not yet fully implemented")
    }
}

// MARK: RuleConfiguration conformances

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

    mutating func apply(_ value: Any?, ruleID: String) throws {
        if let value {
            try apply(configuration: value)
        }
    }

    init(fromAny value: Any, context ruleID: String) throws {
        throw Issue.genericError("Do not call this initializer")
    }
}

public extension SeverityConfiguration {
    /// Severity configurations are special in that they shall not be nested when an option name is provided.
    /// Instead, their only option value must be used together with the option name.
    func asDescription(with key: String) -> RuleConfigurationDescription {
        let description = RuleConfigurationDescription.from(configuration: self)
        if key.isEmpty {
            return description
        }
        guard let option = description.options.onlyElement?.value, case .symbol = option else {
            queuedFatalError(
                """
                Severity configurations must have exactly one option that is a violation severity.
                """
            )
        }
        return RuleConfigurationDescription(options: [key => option])
    }
}
