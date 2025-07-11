import SwiftLintCore

@AcceptableByConfigurationElement
enum TypeBodyLengthCheckType: String, CaseIterable, Comparable {
    case `actor` = "actor"
    case `class` = "class"
    case `enum` = "enum"
    case `extension` = "extension"
    case `protocol` = "protocol"
    case `struct` = "struct"

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

@AutoConfigParser
struct TypeBodyLengthConfiguration: SeverityLevelsBasedRuleConfiguration {
    typealias Parent = TypeBodyLengthRule

    @ConfigurationElement(inline: true)
    private(set) var severityConfiguration = SeverityLevelsConfiguration<Parent>(warning: 250, error: 350)
    @ConfigurationElement(key: "excluded_types")
    private(set) var excludedTypes = Set<TypeBodyLengthCheckType>([.extension, .protocol])
}
