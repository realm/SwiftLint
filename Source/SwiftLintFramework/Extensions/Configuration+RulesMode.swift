public extension Configuration {
    /// Returns the rule for the specified ID, if configured in this configuration.
    ///
    /// - parameter ruleID: The identifier for the rule to look up.
    ///
    /// - returns: The rule for the specified ID, if configured in this configuration.
    func configuredRule(forID ruleID: String) -> Rule? {
        rules.first { rule in
            guard type(of: rule).description.identifier == ruleID else {
                return false
            }
            guard let customRules = rule as? CustomRules else {
                return true
            }
            return !customRules.configuration.customRuleConfigurations.isEmpty
        }
    }

    /// Represents how a Configuration object can be configured with regards to rules.
    enum RulesMode {
        /// The default rules mode, which will enable all rules that aren't defined as being opt-in
        /// (conforming to the `OptInRule` protocol), minus the rules listed in `disabled`, plus the rules listed in
        /// `optIn`.
        case `default`(disabled: Set<String>, optIn: Set<String>)

        /// Only enable the rules explicitly listed.
        case only(Set<String>)

        /// Enable all available rules.
        case allEnabled

        internal init(
            enableAllRules: Bool,
            onlyRules: [String],
            optInRules: [String],
            disabledRules: [String],
            analyzerRules: [String]
        ) throws {
            func warnAboutDuplicates(in identifiers: [String]) {
                if Set(identifiers).count != identifiers.count {
                    let duplicateRules = identifiers.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
                        .filter { $0.1 > 1 }
                    for duplicateRule in duplicateRules {
                        queuedPrintError("warning: '\(duplicateRule.0)' is listed \(duplicateRule.1) times")
                    }
                }
            }

            if enableAllRules {
                self = .allEnabled
            } else if onlyRules.isNotEmpty {
                if disabledRules.isNotEmpty || optInRules.isNotEmpty {
                    throw ConfigurationError.generic(
                        "'\(Configuration.Key.disabledRules.rawValue)' or " +
                            "'\(Configuration.Key.optInRules.rawValue)' cannot be used in combination " +
                        "with '\(Configuration.Key.onlyRules.rawValue)'"
                    )
                }

                warnAboutDuplicates(in: onlyRules + analyzerRules)
                self = .only(Set(onlyRules + analyzerRules))
            } else {
                warnAboutDuplicates(in: disabledRules)

                let effectiveOptInRules: [String]
                if optInRules.contains(RuleIdentifier.all.stringRepresentation) {
                    let allOptInRules = primaryRuleList.list.compactMap { ruleID, ruleType in
                        ruleType is OptInRule.Type && !(ruleType is AnalyzerRule.Type) ? ruleID : nil
                    }
                    effectiveOptInRules = Array(Set(allOptInRules + optInRules))
                } else {
                    effectiveOptInRules = optInRules
                }

                warnAboutDuplicates(in: effectiveOptInRules + analyzerRules)
                self = .default(disabled: Set(disabledRules), optIn: Set(effectiveOptInRules + analyzerRules))
            }
        }

        internal func applied(aliasResolver: (String) -> String) -> RulesMode {
            switch self {
            case let .default(disabled, optIn):
                return .default(
                    disabled: Set(disabled.map(aliasResolver)),
                    optIn: Set(optIn.map(aliasResolver))
                )

            case let .only(onlyRules):
                return .only(Set(onlyRules.map(aliasResolver)))

            case .allEnabled:
                return .allEnabled
            }
        }

        internal func activateCustomRuleIdentifiers(allRulesWrapped: [ConfigurationRuleWrapper]) -> RulesMode {
            // In the only mode, if the custom rules rule is enabled, all custom rules are also enabled implicitly
            // This method makes the implicitly explicit
            switch self {
            case let .only(onlyRules) where onlyRules.contains { $0 == CustomRules.description.identifier }:
                let customRulesRule = (allRulesWrapped.first { $0.rule is CustomRules })?.rule as? CustomRules
                let customRuleIdentifiers = customRulesRule?.configuration.customRuleConfigurations.map(\.identifier)
                return .only(onlyRules.union(Set(customRuleIdentifiers ?? [])))

            default:
                return self
            }
        }
    }
}
