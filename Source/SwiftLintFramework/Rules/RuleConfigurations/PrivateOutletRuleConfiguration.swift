import Foundation

public struct PrivateOutletRuleConfiguration: RuleConfiguration, Equatable {
    var severityConfiguration = SeverityConfiguration(.warning)
    var allowPrivateSet = false
    var allowInternal = false
    var allowInternalSet = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", allow_private_set: \(allowPrivateSet)" +
            ", allow_internal: \(allowInternal)" +
        ", allow_internal_set: \(allowInternalSet)"
    }

    public init(allowPrivateSet: Bool, allowInternal: Bool, allowInternalSet: Bool) {
        self.allowPrivateSet = allowPrivateSet
        self.allowInternal = allowInternal
        self.allowInternalSet = allowInternalSet
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        allowPrivateSet = (configuration["allow_private_set"] as? Bool == true)
        allowInternal = (configuration["allow_internal"] as? Bool == true)
        allowInternalSet = (configuration["allow_internal_set"] as? Bool == true)

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

public func == (lhs: PrivateOutletRuleConfiguration,
                rhs: PrivateOutletRuleConfiguration) -> Bool {
    return lhs.allowPrivateSet == rhs.allowPrivateSet &&
        lhs.allowInternal == rhs.allowInternal &&
        lhs.allowInternalSet == rhs.allowInternalSet &&
        lhs.severityConfiguration == rhs.severityConfiguration
}
