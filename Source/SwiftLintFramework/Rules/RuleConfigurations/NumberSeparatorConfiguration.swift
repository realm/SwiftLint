struct NumberSeparatorConfiguration: SeverityBasedRuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var minimumLength: Int
    private(set) var minimumFractionLength: Int?
    private(set) var excludeRanges: [Range<Double>]

    var consoleDescription: String {
        let minimumFractionLengthDescription: String
        if let minimumFractionLength = minimumFractionLength {
            minimumFractionLengthDescription = ", minimum_fraction_length: \(minimumFractionLength)"
        } else {
            minimumFractionLengthDescription = ", minimum_fraction_length: none"
        }
        return "severity: \(severityConfiguration.consoleDescription)"
            + ", minimum_length: \(minimumLength)"
            + minimumFractionLengthDescription
    }

    init(minimumLength: Int, minimumFractionLength: Int?, excludeRanges: [Range<Double>]) {
        self.minimumLength = minimumLength
        self.minimumFractionLength = minimumFractionLength
        self.excludeRanges = excludeRanges
    }

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let minimumLength = configuration["minimum_length"] as? Int {
            self.minimumLength = minimumLength
        }

        if let minimumFractionLength = configuration["minimum_fraction_length"] as? Int {
            self.minimumFractionLength = minimumFractionLength
        }

        if let excludeRanges = configuration["exclude_ranges"] as? [[String: Any]] {
            self.excludeRanges = excludeRanges.compactMap { dict in
                guard let min = dict["min"] as? Double, let max = dict["max"] as? Double else { return nil }
                return min ..< max
            }
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
