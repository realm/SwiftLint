public struct ComputedAccessorsOrderRuleConfiguration: RuleConfiguration, Equatable {
    public enum Order: String {
        case getSet = "get_set"
        case setGet = "set_get"
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var order = Order.getSet

    public var consoleDescription: String {
        return [severityConfiguration.consoleDescription, "order: \(order.rawValue)"].joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
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
