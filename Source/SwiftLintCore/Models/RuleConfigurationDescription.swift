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
public struct RuleConfigurationDescription: HumanReadable, Equatable {
    fileprivate let options: [RuleConfigurationOption]

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

/// A type that can be converted into a configuration option.
public protocol RuleConfigurationOptionConvertible {
    /// Convert an object to a configuration option.
    ///
    /// - Returns: A configuration option for the object.
    func makeOption() -> RuleConfigurationOption
}

/// A single option of a `RuleConfigurationDescription`.
public struct RuleConfigurationOption: RuleConfigurationOptionConvertible, HumanReadable, Equatable {
    /// Type of an option.
    public enum OptionType: Equatable {
        case flag(Bool)
        case string(String)
        case symbol(String)
        case integer(Int)
        case float(Double)
        case severity(ViolationSeverity)
        case list([OptionType])
        case nested(RuleConfigurationDescription)
    }

    /// An option serving as a marker for an empty configuration description.
    public static let noOptions = Self(key: "<nothing>", value: .flag(false))

    fileprivate let key: String
    fileprivate let value: OptionType

    public func makeOption() -> RuleConfigurationOption {
        self
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
}

extension RuleConfigurationOption.OptionType: HumanReadable {
    public func markdown() -> String {
        switch self {
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

    public static func buildExpression(_ expression: RuleConfigurationOptionConvertible) -> Description {
        Description(options: [expression.makeOption()])
    }

    public static func buildExpression(_ expression: any RuleConfiguration) -> Description {
        expression.parameterDescription ?? Description(options: [])
    }

    public static func buildArray(_ components: [Description]) -> Description {
        Description(options: components.flatMap { $0.options })
    }
}

infix operator =>: MultiplicationPrecedence

public extension RuleConfigurationOption.OptionType {
    /// Operator enabling an easy way to create a configuration option.
    ///
    /// - Parameters:
    ///   - key: Name of the option.
    ///   - value: Value of the option.
    ///
    /// - Returns: A configuration option built up by the given data.
    static func => (key: String, value: RuleConfigurationOption.OptionType) -> RuleConfigurationOption {
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

extension ViolationSeverity: RuleConfigurationOptionConvertible {
    public func makeOption() -> RuleConfigurationOption {
        "severity" => .symbol(rawValue)
    }
}
