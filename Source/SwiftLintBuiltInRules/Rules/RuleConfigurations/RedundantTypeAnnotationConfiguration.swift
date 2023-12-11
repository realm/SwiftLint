import SwiftLintCore

@AutoApply
struct RedundantTypeAnnotationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = RedundantTypeAnnotationRule

    @ConfigurationElement(key: "severity")
    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "ignored_annotations")
    var ignoredAnnotations = Set<String>(["IBInspectable"])
}
