import SwiftLintCore

@AutoApply
struct RedundantTypeAnnotationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantTypeAnnotationRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignore_attributes")
    var ignoreAttributes = Set<String>(["IBInspectable"])
}
