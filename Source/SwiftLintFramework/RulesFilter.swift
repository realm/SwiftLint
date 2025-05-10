package final class RulesFilter {
    package struct ExcludingOptions: OptionSet {
        package let rawValue: Int

        package init(rawValue: Int) {
            self.rawValue = rawValue
        }

        package static let enabled = Self(rawValue: 1 << 0)
        package static let disabled = Self(rawValue: 1 << 1)
        package static let uncorrectable = Self(rawValue: 1 << 2)
    }

    private let allRules: RuleList
    private let enabledRules: [any Rule]

    package init(allRules: RuleList = RuleRegistry.shared.list, enabledRules: [any Rule]) {
        self.allRules = allRules
        self.enabledRules = enabledRules
    }

    package func getRules(excluding excludingOptions: ExcludingOptions) -> RuleList {
        if excludingOptions.isEmpty {
            return allRules
        }

        let filtered: [any Rule.Type] = allRules.list.compactMap { ruleID, ruleType in
            let enabledRule = enabledRules.first { rule in
                type(of: rule).identifier == ruleID
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
