public struct TypeACLOrderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var order: [AccessControlLevel] = [
        .open,
        .public,
        .internal,
        .fileprivate,
        .private
    ]

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", order: \(String(describing: order))"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        guard let orderConfig = configuration["order"] as? [String] else { return }
        let customOrder = orderConfig.compactMap { AccessControlLevel(description: $0) }

        if customOrder.isNotEmpty {
            self.order = customOrder
        }
    }
}
