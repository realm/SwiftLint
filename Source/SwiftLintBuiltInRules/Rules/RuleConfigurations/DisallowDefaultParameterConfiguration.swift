import SwiftLintCore

@AutoConfigParser
struct DisallowDefaultParameterConfiguration: SeverityBasedRuleConfiguration {
    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(
        key: "disallowed_access_levels",
        postprocessor: { $0 = Set($0.sorted()) }
    )
    private(set) var disallowedAccessLevels: Set<AccessLevel> = [.private, .internal]

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
