import SwiftLintCore

@AutoConfigParser
struct OneDeclarationPerFileConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = OneDeclarationPerFileRule

    @AcceptableByConfigurationElement
    enum AllowedType: String, CaseIterable {
        case `actor`
        case `class`
        case `enum`
        case `protocol`
        case `struct`

        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    @ConfigurationElement(key: "allowed_types")
    private(set) var allowedTypes: [AllowedType] = []

    var enabledTypes: Set<AllowedType> {
        Set(self.allowedTypes)
    }
}
