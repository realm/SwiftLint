import SwiftLintCore

@AutoApply
struct ExplicitTypeInterfaceConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ExplicitTypeInterfaceRule

    @MakeAcceptableByConfigurationElement
    enum VariableKind: String, CaseIterable {
        case instance
        case local
        case `static`
        case `class`

        static let all = Set(allCases)
    }

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "excluded")
    private(set) var excluded = [VariableKind]()
    @ConfigurationElement(key: "allow_redundancy")
    private(set) var allowRedundancy = false

    var allowedKinds: Set<VariableKind> {
        VariableKind.all.subtracting(excluded)
    }
}
