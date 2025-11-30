import SwiftLintCore

@AutoConfigParser
struct FileNameNoSpaceConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = Set<String>()
}
