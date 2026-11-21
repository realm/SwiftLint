public extension Configuration {
    /// Returns the rule for the specified ID, if configured in this configuration.
    ///
    /// - parameter ruleID: The identifier for the rule to look up.
    ///
    /// - returns: The rule for the specified ID, if configured in this configuration.
    func configuredRule(forID ruleID: String) -> (any Rule)? {
        rules.first { rule in
            if type(of: rule).identifier == ruleID {
                if let customRules = rule as? CustomRules {
                    return customRules.configuration.customRuleConfigurations.isNotEmpty
                }
                return true
            }
            return false
        }
    }

    /// Represents how a Configuration object can be configured with regards to rules.
    enum RulesMode: Equatable {
        /// The default rules mode, which will enable all rules that aren't defined as being opt-in
        /// (conforming to the `OptInRule` protocol), minus the rules listed in `disabled`, plus the rules listed in
        /// `optIn`.
        case defaultConfiguration(disabled: Set<String>, optIn: Set<String>)

        /// Only enable the rules explicitly listed in the configuration files.
        case onlyConfiguration(Set<String>)

        /// Only enable the rule(s) explicitly listed on the command line (and their aliases). `--only-rule` can be
        /// specified multiple times to enable multiple rules.
        case onlyCommandLine(Set<String>)

        /// Enable all available rules.
        case allCommandLine

        internal init(
            enableAllRules: Bool,
            onlyRule: [String],
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
                        Issue.listedMultipleTime(ruleID: duplicateRule.0, times: duplicateRule.1).print()
                    }
                }
            }

            if enableAllRules {
                self = .allCommandLine
            } else if onlyRule.isNotEmpty {
                self = .onlyCommandLine(Set(onlyRule))
            } else if onlyRules.isNotEmpty {
                if disabledRules.isNotEmpty || optInRules.isNotEmpty {
                    throw Issue.genericWarning(
                        "'\(Configuration.Key.disabledRules.rawValue)' or " +
                            "'\(Configuration.Key.optInRules.rawValue)' cannot be used in combination " +
                        "with '\(Configuration.Key.onlyRules.rawValue)'"
                    )
                }

                warnAboutDuplicates(in: onlyRules + analyzerRules)
                self = .onlyConfiguration(Set(onlyRules + analyzerRules))
            } else {
                warnAboutDuplicates(in: disabledRules)

                let effectiveOptInRules: [String]
                if optInRules.contains(RuleIdentifier.all.stringRepresentation) {
                    let allOptInRules = RuleRegistry.shared.list.list.compactMap { ruleID, ruleType in
                        ruleType is any OptInRule.Type && !(ruleType is any AnalyzerRule.Type) ? ruleID : nil
                    }
                    effectiveOptInRules = Array(Set(allOptInRules + optInRules))
                } else {
                    effectiveOptInRules = optInRules
                }

                let effectiveAnalyzerRules: [String]
                if analyzerRules.contains(RuleIdentifier.all.stringRepresentation) {
                    let allAnalyzerRules = RuleRegistry.shared.list.list.compactMap { ruleID, ruleType in
                        ruleType is any AnalyzerRule.Type ? ruleID : nil
                    }
                    effectiveAnalyzerRules = allAnalyzerRules
                } else {
                    effectiveAnalyzerRules = analyzerRules
                }

                warnAboutDuplicates(in: effectiveOptInRules + effectiveAnalyzerRules)
                self = .defaultConfiguration(
                    disabled: Set(disabledRules), optIn: Set(effectiveOptInRules + effectiveAnalyzerRules)
                )
            }
        }

        internal func applied(aliasResolver: (String) -> String) -> Self {
            switch self {
            case let .defaultConfiguration(disabled, optIn):
                return .defaultConfiguration(
                    disabled: Set(disabled.map(aliasResolver)),
                    optIn: Set(optIn.map(aliasResolver))
                )

            case let .onlyConfiguration(onlyRules):
                return .onlyConfiguration(Set(onlyRules.map(aliasResolver)))

            case let .onlyCommandLine(onlyRules):
                return .onlyCommandLine(Set(onlyRules.map(aliasResolver)))

            case .allCommandLine:
                return .allCommandLine
            }
        }

        internal func activateCustomRuleIdentifiers(allRulesWrapped: [ConfigurationRuleWrapper]) -> Self {
            // In the "only" modes the parent `custom_rules` rule and the individual custom rules are
            // entangled: enabling `custom_rules` implies enabling every custom rule, and enabling any
            // individual custom rule requires the parent `custom_rules` rule to be enabled too.
            // This method makes those implicit relations explicit so that both `only_rules` (config)
            // and `--only-rule` (command line) behave consistently — previously `--only-rule` left
            // custom rules silently disabled, and `only_rules: [<individual_custom_rule>]` did too.
            switch self {
            case let .onlyConfiguration(onlyRules):
                return .onlyConfiguration(Self.withCustomRulesActivated(onlyRules, allRulesWrapped: allRulesWrapped))

            case let .onlyCommandLine(onlyRules):
                return .onlyCommandLine(Self.withCustomRulesActivated(onlyRules, allRulesWrapped: allRulesWrapped))

            default:
                return self
            }
        }

        private static func withCustomRulesActivated(
            _ onlyRules: Set<String>,
            allRulesWrapped: [ConfigurationRuleWrapper]
        ) -> Set<String> {
            let customRuleIdentifiers = Set(allRulesWrapped.customRules?.customRuleIdentifiers ?? [])
            var onlyRules = onlyRules
            if onlyRules.contains(CustomRules.identifier) {
                // `custom_rules` is enabled → enable all of its custom rules.
                onlyRules.formUnion(customRuleIdentifiers)
            } else if !onlyRules.isDisjoint(with: customRuleIdentifiers) {
                // At least one individual custom rule is enabled → enable the parent `custom_rules` rule.
                onlyRules.insert(CustomRules.identifier)
            }
            return onlyRules
        }
    }
}
