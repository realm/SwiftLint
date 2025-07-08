import SwiftLintCore

@AutoConfigParser
struct FunctionNameWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = FunctionNameWhitespaceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "generic_space")
    private(set) var genericSpace = GenericSpaceType.noSpace

    @AcceptableByConfigurationElement
    enum GenericSpaceType: String {
        case noSpace = "no_space"
        case leadingSpace = "leading_space"
        case trailingSpace = "trailing_space"
        case leadingTrailingSpace = "leading_trailing_space"

        var reasonForName: String {
            switch self {
            case .noSpace:
                return "Remove space after function name"
            case .leadingSpace:
                return "Insert a single space after function name"
            case .trailingSpace:
                return "Remove space after function name"
            case .leadingTrailingSpace:
                return "Insert a single space after function name"
            }
        }

        var reasonForGenericAngleBracket: String {
            switch self {
            case .noSpace, .leadingSpace:
                return "Remove space after closing angle bracket"
            case .trailingSpace, .leadingTrailingSpace:
                return "Insert a single space after closing angle bracket"
            }
        }
    }
}
