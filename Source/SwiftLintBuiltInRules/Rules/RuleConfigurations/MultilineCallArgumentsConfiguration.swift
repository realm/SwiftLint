import SwiftLintCore

/// The indentation style for auto-correction.
///
/// - `tab`: Use tab character for indentation
/// - `spaces(count:)`: Use the specified number of spaces
enum IndentationStyle: Hashable, Sendable {
    /// Use tab for indentation.
    case tab
    /// Use spaces for indentation with the specified count.
    case spaces(count: Int)

    /// Returns the indentation string for one level of indentation.
    internal var indentationString: String {
        switch self {
        case .tab:
            return "\t"
        case .spaces(let count):
            return String(repeating: " ", count: count)
        }
    }
}

extension IndentationStyle: AcceptableByConfigurationElement {
    func asOption() -> OptionType {
        switch self {
        case .tab:
            return .string("tab")
        case .spaces(let count):
            return .integer(count)
        }
    }

    init(fromAny value: Any, context ruleID: String) throws(Issue) {
        switch value {
        case let intValue as Int:
            guard intValue >= 1 else {
                throw Issue.invalidConfiguration(
                    ruleID: ruleID,
                    message: "Option 'indentation' must be a positive integer or the string \"tab\""
                )
            }
            self = .spaces(count: intValue)
        case let stringValue as String where stringValue == "tab":
            self = .tab
        default:
            throw Issue.invalidConfiguration(
                ruleID: ruleID,
                message: "Option 'indentation' must be a positive integer or the string \"tab\""
            )
        }
    }
}

/// Configuration for the `multiline_call_arguments` rule.
///
/// This configuration controls how function calls with multiple arguments should be formatted.
///
/// Example configuration:
/// ```yaml
/// multiline_call_arguments:
///   allows_single_line: false  # Force all multi-arg calls to be multiline
///   indentation: 4             # 4 spaces (default)
/// ```
///
/// Or with tab:
/// ```yaml
/// multiline_call_arguments:
///   indentation: "tab"
/// ```
@AutoConfigParser
struct MultilineCallArgumentsConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    /// Whether calls with multiple arguments are allowed on a single line.
    /// When `false`, any call with 2+ arguments on one line will trigger a violation.
    @ConfigurationElement(key: "allows_single_line")
    private(set) var allowsSingleLine = true

    /// Maximum number of arguments allowed on a single line.
    /// When set, calls with more than this number of arguments on one line will trigger a violation.
    /// Has no effect when `allows_single_line` is `false`.
    @ConfigurationElement(key: "max_number_of_single_line_parameters")
    private(set) var maxNumberOfSingleLineParameters: Int?

    /// Indentation style for corrected lines.
    /// Can be an integer (number of spaces) or the string "tab".
    @ConfigurationElement(key: "indentation")
    private(set) var indentationStyle: IndentationStyle = .spaces(count: 4)

    func validate() throws(Issue) {
        guard let maxNumberOfSingleLineParameters else { return }

        guard maxNumberOfSingleLineParameters >= 1 else {
            throw Issue.inconsistentConfiguration(
                ruleID: Parent.identifier,
                message: "Option '\($maxNumberOfSingleLineParameters.key)' should be >= 1."
            )
        }

        if maxNumberOfSingleLineParameters > 1, !allowsSingleLine {
            throw Issue.inconsistentConfiguration(
                ruleID: Parent.identifier,
                message: """
                         Option '\($maxNumberOfSingleLineParameters.key)' has no effect when \
                         '\($allowsSingleLine.key)' is false
                         """
            )
        }
    }
}
