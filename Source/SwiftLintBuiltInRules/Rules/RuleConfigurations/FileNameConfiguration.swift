import SwiftLintCore

@AutoConfigParser
struct FileNameConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = FileNameRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded: Set = ["main.swift", "LinuxMain.swift"]
    @ConfigurationElement(key: "exclude_path_patterns")
    private(set) var excludePathPatterns: Set<String> = []
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
    func shouldExclude(filePath: String) -> Bool {
        let fileName = filePath.bridge().lastPathComponent
        if excluded.contains(fileName) {
            return true
        }

        return excludePathPatterns.contains {
            let regex = try? RegularExpression(pattern: "^\($0)$")
            return regex?.regex.firstMatch(in: filePath, range: filePath.fullNSRange) != nil
        }
    }
}
