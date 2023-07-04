import SwiftLintCore

struct FileNameConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = FileNameRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = Set<String>(["main.swift", "LinuxMain.swift"])
    @ConfigurationElement(key: "prefix_pattern")
    private(set) var prefixPattern = ""
    @ConfigurationElement(key: "suffix_pattern")
    private(set) var suffixPattern = "\\+.*"
    @ConfigurationElement(key: "nested_type_separator")
    private(set) var nestedTypeSeparator = "."

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severity = configurationDict[$severityConfiguration] {
            try severityConfiguration.apply(configuration: severity)
        }
        if let excluded = [String].array(of: configurationDict[$excluded]) {
            self.excluded = Set(excluded)
        }
        if let prefixPattern = configurationDict[$prefixPattern] as? String {
            self.prefixPattern = prefixPattern
        }
        if let suffixPattern = configurationDict[$suffixPattern] as? String {
            self.suffixPattern = suffixPattern
        }
        if let nestedTypeSeparator = configurationDict[$nestedTypeSeparator] as? String {
            self.nestedTypeSeparator = nestedTypeSeparator
        }
    }
}
