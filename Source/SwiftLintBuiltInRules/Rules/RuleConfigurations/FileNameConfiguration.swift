import SwiftLintCore

@AutoConfigParser
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
    @ConfigurationElement(key: "require_fully_qualified_names")
    private(set) var requireFullyQualifiedNames = false
}

// MARK: - For `excluded` option
extension FileNameConfiguration {
    func shouldExclude(filePath: String) -> Bool {
        let fileName = filePath.bridge().lastPathComponent

        // For backwards compatibility,
        // `excluded` can have a fileName which is invalid as regex.(e.g. "NSString+Extension.swift")
        if excluded.contains(fileName) {
            return true
        }

        return excluded.compactMap {
            try? Regex("^\($0)$").firstMatch(in: filePath)
        }.isNotEmpty
    }
}
