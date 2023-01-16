struct ProhibitedSuperConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    var excluded = [String]()
    var included = ["*"]

    private(set) var resolvedMethodNames = [
        // NSFileProviderExtension
        "providePlaceholder(at:completionHandler:)",
        // NSTextInput
        "doCommand(by:)",
        // NSView
        "updateLayer()",
        // UIViewController
        "loadView()"
    ]

    init() {}

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", excluded: [\(excluded)]" +
            ", included: [\(included)]"
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        if let excluded = [String].array(of: configuration["excluded"]) {
            self.excluded = excluded
        }

        if let included = [String].array(of: configuration["included"]) {
            self.included = included
        }

        resolvedMethodNames = calculateResolvedMethodNames()
    }

    private func calculateResolvedMethodNames() -> [String] {
        var names = [String]()
        if included.contains("*") && !excluded.contains("*") {
            names += resolvedMethodNames
        }
        names += included.filter { $0 != "*" }
        names = names.filter { !excluded.contains($0) }
        return names
    }
}
