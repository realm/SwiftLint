import SwiftLintCore

struct NumberSeparatorConfiguration: SeverityBasedRuleConfiguration, Equatable {
    typealias Parent = NumberSeparatorRule

    @ConfigurationElement("severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement("minimum_length")
    private(set) var minimumLength = 0
    @ConfigurationElement("minimum_fraction_length")
    private(set) var minimumFractionLength: Int? = nil

    private(set) var excludeRanges = [Range<Double>]()

    mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw Issue.unknownConfiguration(ruleID: Parent.identifier)
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
