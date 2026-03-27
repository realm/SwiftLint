import SwiftLintCore

@AutoConfigParser
struct DiscouragedDefaultParameterConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "disallowed_access_levels")
    private(set) var disallowedAccessLevels: Set<AccessControlLevel> = [.internal, .package]

    @AcceptableByConfigurationElement
    enum AccessLevel: String, Comparable {
        case `private`
        case `fileprivate`
        case `internal`
        case `package`

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
