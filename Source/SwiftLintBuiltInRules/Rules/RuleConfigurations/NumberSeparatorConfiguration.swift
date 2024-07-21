import SwiftLintCore

@AutoConfigParser
struct NumberSeparatorConfiguration: SeverityBasedRuleConfiguration {
    typealias Parent = NumberSeparatorRule

    struct ExcludeRange: AcceptableByConfigurationElement, Equatable {
        private let min: Double
        private let max: Double

        func asOption() -> OptionType {
            .symbol("\(min) ..< \(max)")
        }

        init(fromAny value: Any, context ruleID: String) throws {
            guard let values = value as? [String: Any],
                  let min = values["min"] as? Double,
                  let max = values["max"] as? Double else {
                throw Issue.invalidConfiguration(ruleID: ruleID)
            }
            self.min = min
            self.max = max
        }

        func contains(_ value: Double) -> Bool {
            min <= value && value < max
        }
    }

    @ConfigurationElement(key: "severity")
    private(set) var severityConfiguration = SeverityConfiguration<Parent>(.warning)
    @ConfigurationElement(key: "minimum_length")
    private(set) var minimumLength = 0
    @ConfigurationElement(key: "minimum_fraction_length")
    private(set) var minimumFractionLength: Int?
    @ConfigurationElement(key: "exclude_ranges")
    private(set) var excludeRanges = [ExcludeRange]()
}
