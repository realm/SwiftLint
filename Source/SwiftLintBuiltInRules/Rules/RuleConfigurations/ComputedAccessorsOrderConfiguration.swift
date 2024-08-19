import SwiftLintCore

@AutoConfigParser
struct ComputedAccessorsOrderConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = ComputedAccessorsOrderRule

    @AcceptableByConfigurationElement
    enum Order: String {
        case getSet = "get_set"
        case setGet = "set_get"
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order = Order.getSet
}
