import Foundation

public struct ConditionalReturnsOnNewlineConfiguration: RuleConfiguration {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var ifOnly = false

    public var consoleDescription: String {
        return [severityConfiguration.consoleDescription, "if_only: \(ifOnly)"].joined(separator: ", ")
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        ifOnly = configuration["if_only"] as? Bool ?? false

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

extension ConditionalReturnsOnNewlineConfiguration: Equatable {
    public static func == (lhs: ConditionalReturnsOnNewlineConfiguration,
                           rhs: ConditionalReturnsOnNewlineConfiguration) -> Bool {
        return lhs.severityConfiguration == rhs.severityConfiguration &&
            lhs.ifOnly == rhs.ifOnly
    }
}
