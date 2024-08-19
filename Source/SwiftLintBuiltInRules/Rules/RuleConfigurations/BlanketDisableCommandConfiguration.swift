import SwiftLintCore

@AutoConfigParser
struct BlanketDisableCommandConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = BlanketDisableCommandRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "allowed_rules")
    private(set) var allowedRuleIdentifiers: Set<String> = [
        "file_header",
        "file_length",
        "file_name",
        "file_name_no_space",
        "single_test_class",
    ]
    @ConfigurationElement(key: "always_blanket_disable")
    private(set) var alwaysBlanketDisableRuleIdentifiers: Set<String> = []
}
