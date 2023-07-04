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

    static func from(configuration: any RuleConfiguration) -> Self {
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
    public func oneLiner() -> String {
        options.map { $0.oneLiner() }.joined(separator: "; ")
    }

    public func markdown() -> String {
        guard options.isNotEmpty else {
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

/// A single option of a ``RuleConfigurationDescription``.
public struct RuleConfigurationOption: Equatable {
    /// An option serving as a marker for an empty configuration description.
    public static let noOptions = Self(key: "<nothing>", value: .empty)

    fileprivate let key: String
    fileprivate let value: OptionType
}

extension RuleConfigurationOption: Documentable {
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
    public func markdown() -> String {
        switch self {
        case .empty:
            queuedFatalError("Empty options shall not be serialized.")
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
            return value.oneLiner()
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
}

public extension AcceptableByConfigurationElement {
    func asDescription(with key: String) -> RuleConfigurationDescription {
        // By default, this method is just a shortcut applicable for most of the types conforming to the protocol.
        RuleConfigurationDescription(options: [key => asOption()])
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
public struct ConfigurationElement<T: AcceptableByConfigurationElement & Equatable>: AnyConfigurationElement,
                                                                                     Equatable {
    /// Wrapped option value.
    public var wrappedValue: T

    /// The option's name. This field can only be accessed by the element's name prefixed with a `$`.
    public let projectedValue: String

    fileprivate var description: RuleConfigurationDescription {
        wrappedValue.asDescription(with: projectedValue)
    }

    /// Default constructor.
    ///
    /// - Parameters:
    ///   - value: Value to be wrapped.
    ///   - key: Name of the option.
    public init(wrappedValue value: T, key: String) {
        self.wrappedValue = value
        self.projectedValue = key
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

// MARK: AcceptableByConfigurationElement conformances

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
                Severity configurations must have exaclty one option that is a violation severity.
                """
            )
        }
        return RuleConfigurationDescription(options: [key => option])
    }
}
