struct XCTSpecificMatcherConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = XCTSpecificMatcherRule

    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var matchers = Set(Matcher.allCases)

    enum Matcher: String, Hashable, CaseIterable {
        case oneArgumentAsserts = "one-argument-asserts"
        case twoArgumentAsserts = "two-argument-asserts"
    }

    private enum ConfigurationKey: String {
        case severity
        case matchers
    }

    var consoleDescription: String {
        return [
            "severity: \(severityConfiguration.consoleDescription)",
            "\(ConfigurationKey.matchers): \(matchers.map(\.rawValue).sorted().joined(separator: ", "))"
        ].joined(separator: ", ")
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let severityString = configuration[ConfigurationKey.severity.rawValue] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let matchers = configuration[ConfigurationKey.matchers.rawValue] as? [String] {
            self.matchers = Set(matchers.compactMap(Matcher.init(rawValue:)))
        }
    }
}
