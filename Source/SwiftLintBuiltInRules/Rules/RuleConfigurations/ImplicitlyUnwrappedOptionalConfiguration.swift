import SwiftLintCore

@AutoApply
struct ImplicitlyUnwrappedOptionalConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ImplicitlyUnwrappedOptionalRule

    @MakeAcceptableByConfigurationElement
    enum ImplicitlyUnwrappedOptionalModeConfiguration: String { // swiftlint:disable:this type_name
        case all = "all"
        case allExceptIBOutlets = "all_except_iboutlets"
        case weakExceptIBOutlets = "weak_except_iboutlets"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "mode")
    private(set) var mode = ImplicitlyUnwrappedOptionalModeConfiguration.allExceptIBOutlets
}
