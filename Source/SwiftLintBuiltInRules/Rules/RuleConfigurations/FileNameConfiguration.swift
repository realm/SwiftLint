import Foundation
import SourceKittenFramework
import SwiftLintCore

@AutoConfigParser
struct FileNameConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = Set(["main.swift", "LinuxMain.swift"])
    @ConfigurationElement(key: "excluded_paths")
    private(set) var excludedPaths = Set<RegularExpression>()
    @ConfigurationElement(key: "prefix_pattern")
    private(set) var prefixPattern = ""
    @ConfigurationElement(key: "suffix_pattern")
    private(set) var suffixPattern = "\\+.*"
    @ConfigurationElement(key: "nested_type_separator")
    private(set) var nestedTypeSeparator = "."
    @ConfigurationElement(key: "require_fully_qualified_names")
    private(set) var requireFullyQualifiedNames = false
}

extension FileNameConfiguration {
    func shouldExclude(filePath: URL) -> Bool {
        if excluded.contains(filePath.lastPathComponent) {
            return true
        }
        return excludedPaths.contains {
            $0.regex.firstMatch(in: filePath.path, range: filePath.path.fullNSRange) != nil
        }
    }
}
