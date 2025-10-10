import SwiftLintCore

@AutoConfigParser
struct IncompatibleConcurrencyConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = IncompatibleConcurrencyAnnotationRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "global_actors", postprocessor: { $0.insert("MainActor") })
    private(set) var globalActors = Set<String>()
}
