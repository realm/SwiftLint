import SwiftLintCore

@AutoApply // swiftlint:disable:next type_name
struct NonOverridableClassDeclarationConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = NonOverridableClassDeclarationRule

    @MakeAcceptableByConfigurationElement
    enum FinalClassModifier: String {
        case finalClass = "final class"
        case `static` = "static"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>.warning
    @ConfigurationElement(key: "final_class_modifier")
    private(set) var finalClassModifier = FinalClassModifier.finalClass
}
