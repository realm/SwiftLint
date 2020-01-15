public struct SortedImportsConfiguration: RuleConfiguration, Equatable {
    enum TestableImportsConfiguration: String {
        case `default`, top, bottom
    }

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var testableImportsConfiguration = TestableImportsConfiguration.default

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", testable_imports: \(testableImportsConfiguration.rawValue)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let testableImportsConfigString = configuration["testable_imports"] as? String,
            let testableImportsConfig = TestableImportsConfiguration(rawValue: testableImportsConfigString) {
            testableImportsConfiguration = testableImportsConfig
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
