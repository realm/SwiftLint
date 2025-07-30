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
    }
}
