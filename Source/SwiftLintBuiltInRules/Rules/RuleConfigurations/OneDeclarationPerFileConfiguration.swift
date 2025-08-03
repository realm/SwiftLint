import SwiftLintCore

@AutoConfigParser
struct OneDeclarationPerFileConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = OneDeclarationPerFileRule

    @AcceptableByConfigurationElement
    enum IgnoredType: String, CaseIterable {
        case `actor`
        case `class`
        case `enum`
        case `protocol`
        case `struct`
        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(key: "ignored_types")
    private(set) var ignoredTypes: [IgnoredType] = []

    var allowedTypes: Set<IgnoredType> {
        Set(self.ignoredTypes)
    }
}
