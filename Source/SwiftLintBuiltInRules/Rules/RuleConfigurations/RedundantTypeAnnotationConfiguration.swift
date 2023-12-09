import SwiftLintCore

@AutoApply
struct RedundantTypeAnnotationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantTypeAnnotationRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    var ignoredAnnotations = Set<String>(["IBInspectable"])
}
