import SwiftLintCore

@AutoConfigParser
struct SortedImportsConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = SortedImportsRule

    @AcceptableByConfigurationElement
    enum SortedImportsGroupingConfiguration: String {
        /// Sorts import lines based on any import attributes (e.g. `@testable`, `@_exported`, etc.), followed by a case
        /// insensitive comparison of the imported module name.
        case attributes
        /// Sorts import lines based on a case insensitive comparison of the imported module name.
        case names
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "grouping")
    private(set) var grouping = SortedImportsGroupingConfiguration.names
}
