public final class RulesFilter {
    public struct ExcludingOptions: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let enabled = Self(rawValue: 1 << 0)
        public static let disabled = Self(rawValue: 1 << 1)
        public static let uncorrectable = Self(rawValue: 1 << 2)
    }

    private let allRules: RuleList
    private let enabledRules: [any Rule]

    public init(allRules: RuleList = RuleRegistry.shared.list, enabledRules: [any Rule]) {
        self.allRules = allRules
        self.enabledRules = enabledRules
    }

    public func getRules(excluding excludingOptions: ExcludingOptions) -> RuleList {
        if excludingOptions.isEmpty {
            return allRules
        }

        let filtered: [any Rule.Type] = allRules.list.compactMap { ruleID, ruleType in
            let enabledRule = enabledRules.first { rule in
                type(of: rule).description.identifier == ruleID
            }
            let isRuleEnabled = enabledRule != nil

            if excludingOptions.contains(.enabled) && isRuleEnabled {
                return nil
            }
            if excludingOptions.contains(.disabled) && !isRuleEnabled {
                return nil
            }
            if excludingOptions.contains(.uncorrectable) && !(ruleType is any CorrectableRule.Type) {
                return nil
            }

            return ruleType
        }

        return RuleList(rules: filtered)
    }
}
