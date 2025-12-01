import SwiftLintCore

@AutoConfigParser
struct IncompatibleConcurrencyAnnotationConfiguration: SeverityBasedRuleConfiguration {
    // swiftlint:disable:previous type_name

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "global_actors", postprocessor: { $0.insert("MainActor") })
    private(set) var globalActors = Set<String>()
}
