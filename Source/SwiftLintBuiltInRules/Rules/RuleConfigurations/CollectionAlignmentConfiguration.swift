import SwiftLintCore

@AutoApply
struct CollectionAlignmentConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = CollectionAlignmentRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "align_colons")
    private(set) var alignColons = false
}
