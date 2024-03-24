import SwiftLintCore

@AutoApply
struct ComputedAccessorsOrderConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ComputedAccessorsOrderRule

    @MakeAcceptableByConfigurationElement
    enum Order: String {
        case getSet = "get_set"
        case setGet = "set_get"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severity = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order = Order.getSet
}
