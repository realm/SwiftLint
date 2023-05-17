struct AttributesConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = AttributesRule

    var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    private(set) var attributesWithArgumentsAlwaysOnNewLine = true
    private(set) var alwaysOnSameLine = Set<String>()
    private(set) var alwaysOnNewLine = Set<String>()

    var consoleDescription: String {
        return "severity: \(severityConfiguration.consoleDescription)" +
            ", always_on_same_line: \(alwaysOnSameLine.sorted())" +
            ", always_on_line_above: \(alwaysOnNewLine.sorted())"
    }

    init(alwaysOnSameLine: [String] = ["@IBAction", "@NSManaged"],
         alwaysInNewLine: [String] = []) {
        self.alwaysOnSameLine = Set(alwaysOnSameLine)
        self.alwaysOnNewLine = Set(alwaysOnNewLine)
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let attributesWithArgumentsAlwaysOnNewLine
                = configuration["attributes_with_arguments_always_on_line_above"] as? Bool {
            self.attributesWithArgumentsAlwaysOnNewLine = attributesWithArgumentsAlwaysOnNewLine
        }

        if let alwaysOnSameLine = configuration["always_on_same_line"] as? [String] {
            self.alwaysOnSameLine = Set(alwaysOnSameLine)
        }

        if let alwaysOnNewLine = configuration["always_on_line_above"] as? [String] {
            self.alwaysOnNewLine = Set(alwaysOnNewLine)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
