import SwiftLintCore

struct ComputedAccessorsOrderConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = ComputedAccessorsOrderRule

    enum Order: String, AcceptableByConfigurationElement {
        case getSet = "get_set"
        case setGet = "set_get"

        func asOption() -> OptionType {
            .symbol(rawValue)
        }
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "order")
    private(set) var order = Order.getSet

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let orderString = configuration["order"] as? String,
            let order = Order(rawValue: orderString) {
            self.order = order
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
