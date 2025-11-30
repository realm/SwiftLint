import SwiftLintCore

@AutoConfigParser
struct FunctionNameWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "generic_spacing")
    private(set) var genericSpacing = GenericSpacingType.noSpace

    @AcceptableByConfigurationElement
    enum GenericSpacingType: String {
        case noSpace = "no_space"
        case leadingSpace = "leading_space"
        case trailingSpace = "trailing_space"
        case leadingTrailingSpace = "leading_trailing_space"

        var beforeGenericViolationReason: String {
            switch self {
            case .noSpace, .trailingSpace:
                "Superfluous space between function name and generic parameter(s)"
            case .leadingSpace, .leadingTrailingSpace:
                "Missing space between function name and generic parameter(s)"
            }
        }

        var afterGenericViolationReason: String {
            switch self {
            case .noSpace, .leadingSpace:
                "Superfluous space after generic parameter(s)"
            case .trailingSpace, .leadingTrailingSpace:
                "Missing space after generic parameter(s)"
            }
        }
    }
}
