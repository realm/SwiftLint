import SwiftLintCore

@AutoApply
struct FileNameConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = FileNameRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded: Set = ["main.swift", "LinuxMain.swift"]
    @ConfigurationElement(key: "prefix_pattern")
    private(set) var prefixPattern = ""
    @ConfigurationElement(key: "suffix_pattern")
    private(set) var suffixPattern = "\\+.*"
    @ConfigurationElement(key: "nested_type_separator")
    private(set) var nestedTypeSeparator = "."
}
