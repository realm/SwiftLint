import SwiftLintCore

struct NumberSeparatorConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = NumberSeparatorRule

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "minimum_length")
    private(set) var minimumLength = 0
    @ConfigurationElement(key: "minimum_fraction_length")
    private(set) var minimumFractionLength: Int?

    private(set) var excludeRanges = [Range<Double>]()

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
        }

        if let minimumLength = configuration[$minimumLength] as? Int {
            self.minimumLength = minimumLength
        }

        if let minimumFractionLength = configuration[$minimumFractionLength] as? Int {
            self.minimumFractionLength = minimumFractionLength
        }

        if let excludeRanges = configuration["exclude_ranges"] as? [[String: Any]] {
            self.excludeRanges = excludeRanges.compactMap { dict in
                guard let min = dict["min"] as? Double, let max = dict["max"] as? Double else { return nil }
                return min ..< max
            }
        }

        if let severityString = configuration[$severityConfiguration] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}
