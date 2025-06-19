import SwiftLintCore

@AutoConfigParser
struct VerticalWhitespaceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = VerticalWhitespaceRule

    static let defaultDescriptionReason = "Limit vertical whitespace to a single empty line"

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "max_empty_lines")
    private(set) var maxEmptyLines = 1

    var configuredDescriptionReason: String {
        guard maxEmptyLines == 1 else {
            return "Limit vertical whitespace to maximum \(maxEmptyLines) empty lines"
        }
        return Self.defaultDescriptionReason
    }
}
