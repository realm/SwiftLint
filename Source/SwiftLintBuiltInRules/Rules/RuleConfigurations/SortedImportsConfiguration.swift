import SwiftLintCore

@AutoConfigParser
struct SortedImportsConfiguration: SeverityBasedRuleConfiguration {
    @AcceptableByConfigurationElement
    enum Grouping: String {
        /// Sorts import lines based on any import attributes (e.g. `@testable`, `@_exported`, etc.), followed by a case
        /// insensitive comparison of the imported module name.
        case attributes
        /// Sorts import lines based on a case insensitive comparison of the imported module name.
        case names
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "grouping")
    private(set) var grouping = Grouping.names
}
