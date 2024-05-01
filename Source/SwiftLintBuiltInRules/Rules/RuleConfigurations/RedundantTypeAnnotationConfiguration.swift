import SwiftLintCore

@AutoApply
struct RedundantTypeAnnotationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantTypeAnnotationRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_attributes")
    var ignoreAttributes = Set<String>(["IBInspectable"])
    @ConfigurationElement(key: "consider_default_literal_types_redundant")
    private(set) var considerDefaultLiteralTypesRedundant = false
}
