import SwiftLintCore

@AutoApply
struct FileNameNoSpaceConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = FileNameNoSpaceRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = Set<String>()
}
