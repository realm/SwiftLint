private func toExplicitInitMethod(typeName: String) -> String {
    return "\(typeName).init"
}

struct DiscouragedDirectInitConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = DiscouragedDirectInitRule

    var severityConfiguration = SeverityConfiguration<Parent>(.warning)

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" + ", types: \(discouragedInits.sorted(by: <))"
    }

    private(set) var discouragedInits: Set<String>

    private let defaultDiscouragedInits = [
        "Bundle",
        "NSError",
        "UIDevice"
    ]

    init() {
        discouragedInits = Set(defaultDiscouragedInits + defaultDiscouragedInits.map(toExplicitInitMethod))
    }

    // MARK: - RuleConfiguration

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let types = [String].array(of: configuration["types"]) {
            discouragedInits = Set(types + types.map(toExplicitInitMethod))
        }
    }
}
