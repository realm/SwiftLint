private func toExplicitInitMethod(typeName: String) -> String {
    return "\(typeName).init"
}

public struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration, Equatable {
    public var severityConfiguration = SeverityConfiguration(.warning)

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", types: \(discouragedInits.sorted(by: <))"
    }

    public private(set) var discouragedInits: Set<String>

    private let defaultDiscouragedInits = [
        "Bundle",
        "UIDevice"
    ]

    init() {
        discouragedInits = Set(defaultDiscouragedInits + defaultDiscouragedInits.map(toExplicitInitMethod))
    }

    // MARK: - RuleConfiguration

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let types = [String].array(of: configuration["types"]) {
            discouragedInits = Set(types + types.map(toExplicitInitMethod))
        }
    }
}
