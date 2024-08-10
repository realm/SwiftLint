import Foundation

internal extension Configuration {
    struct RulesWrapper {
        // MARK: - Properties
        private static var isOptInRuleCache: [String: Bool] = [:]
        private static var invalidRuleIdsWarnedAbout: Set<String> = []

        private let aliasResolver: @Sendable (String) -> String
        private let validRuleIdentifiers: Set<String>

        let allRulesWrapped: [ConfigurationRuleWrapper]
        let mode: RulesMode
        let resultingRules: [any Rule]
        let disabledRuleIdentifiers: [String]

        // MARK: - Initializers
        init(
            mode: RulesMode,
            allRulesWrapped: [ConfigurationRuleWrapper],
            aliasResolver: @escaping @Sendable (String) -> String,
            originatesFromMergingProcess: Bool = false
        ) {
            self.allRulesWrapped = allRulesWrapped
            self.aliasResolver = aliasResolver
            let mode = mode.applied(aliasResolver: aliasResolver)
            let regularRuleIdentifiers = allRulesWrapped.map { type(of: $0.rule).description.identifier }
            let configurationCustomRulesIdentifiers =
                (allRulesWrapped.first { $0.rule is CustomRules }?.rule as? CustomRules)?
                    .configuration.customRuleConfigurations.map(\.identifier) ?? []
            self.validRuleIdentifiers = Set(regularRuleIdentifiers + configurationCustomRulesIdentifiers)
            // If this instance originates from a merging process, some custom rules may be treated as not activated
            // Otherwise, custom rules should be treated as implicitly activated
            self.mode = originatesFromMergingProcess
                ? mode
                : mode.activateCustomRuleIdentifiers(allRulesWrapped: allRulesWrapped)

            // Calculate value
            let customRulesFilter: (RegexConfiguration<CustomRules>) -> (Bool)
            var resultingRules = [any Rule]()
            switch self.mode {
            case .allEnabled:
                customRulesFilter = { _ in true }
                resultingRules = allRulesWrapped.map(\.rule)

            case var .only(onlyRulesRuleIdentifiers):
                customRulesFilter = { onlyRulesRuleIdentifiers.contains($0.identifier) }
                onlyRulesRuleIdentifiers = Self.validate(ruleIds: onlyRulesRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWrapped.filter { tuple in
                    onlyRulesRuleIdentifiers.contains(type(of: tuple.rule).description.identifier)
                }.map(\.rule)

            case var .default(disabledRuleIdentifiers, optInRuleIdentifiers):
                customRulesFilter = { !disabledRuleIdentifiers.contains($0.identifier) }
                disabledRuleIdentifiers = Self.validate(ruleIds: disabledRuleIdentifiers, valid: validRuleIdentifiers)
                optInRuleIdentifiers = Self.validate(optInRuleIds: optInRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWrapped.filter { tuple in
                    let id = type(of: tuple.rule).description.identifier
                    return !disabledRuleIdentifiers.contains(id)
                        && (!(tuple.rule is any OptInRule) || optInRuleIdentifiers.contains(id))
                }.map(\.rule)
            }

            // Filter custom rules
            if var customRulesRule = (resultingRules.first { $0 is CustomRules }) as? CustomRules {
                customRulesRule.configuration.customRuleConfigurations =
                    customRulesRule.configuration.customRuleConfigurations.filter(customRulesFilter)
                resultingRules = resultingRules.filter { !($0 is CustomRules) } + [customRulesRule]
            }

            // Sort by name
            resultingRules = resultingRules.sorted {
                type(of: $0).description.identifier < type(of: $1).description.identifier
            }
            self.resultingRules = resultingRules

            self.disabledRuleIdentifiers =
                switch mode {
                case let .default(disabled, _):
                    Self.validate(ruleIds: disabled, valid: validRuleIdentifiers, silent: true)
                        .sorted(by: <)

                case let .only(onlyRules):
                    Self.validate(
                        ruleIds: Set(allRulesWrapped
                            .map { type(of: $0.rule).description.identifier }
                            .filter { !onlyRules.contains($0) }),
                        valid: validRuleIdentifiers,
                        silent: true
                    ).sorted(by: <)

                case .allEnabled:
                    []
                }
        }

        // MARK: - Methods: Validation
        private static func validate(optInRuleIds: Set<String>, valid: Set<String>) -> Set<String> {
            validate(ruleIds: optInRuleIds, valid: valid.union([RuleIdentifier.all.stringRepresentation]))
        }

        private static func validate(ruleIds: Set<String>, valid: Set<String>, silent: Bool = false) -> Set<String> {
            // Process invalid rule identifiers
            if !silent {
                let invalidRuleIdentifiers = ruleIds.subtracting(valid)
                if !invalidRuleIdentifiers.isEmpty {
                    for invalidRuleIdentifier in invalidRuleIdentifiers.subtracting(Self.invalidRuleIdsWarnedAbout) {
                        Self.invalidRuleIdsWarnedAbout.insert(invalidRuleIdentifier)
                        queuedPrintError(
                            "warning: '\(invalidRuleIdentifier)' is not a valid rule identifier"
                        )
                    }

                    queuedPrintError(
                        "Valid rule identifiers:\n\(valid.sorted().joined(separator: "\n"))"
                    )
                }
            }

            // Return valid rule identifiers
            return ruleIds.intersection(valid)
        }

        // MARK: Merging
        func merged(with child: Self) -> Self {
            // Merge allRulesWrapped
            let newAllRulesWrapped = mergedAllRulesWrapped(with: child)

            // Merge mode
            let validRuleIdentifiers = validRuleIdentifiers.union(child.validRuleIdentifiers)
            let newMode: RulesMode =
                switch child.mode {
                case let .default(childDisabled, childOptIn):
                    mergeDefaultMode(
                        newAllRulesWrapped: newAllRulesWrapped,
                        child: child,
                        childDisabled: childDisabled,
                        childOptIn: childOptIn,
                        validRuleIdentifiers: validRuleIdentifiers
                    )

                case let .only(childOnlyRules):
                    // Always use the child only rules
                    .only(childOnlyRules)

                case .allEnabled:
                    // Always use .allEnabled mode
                    .allEnabled
                }

            // Assemble & return merged rules
            return Self(
                mode: newMode,
                allRulesWrapped: mergedCustomRules(newAllRulesWrapped: newAllRulesWrapped, with: child),
                aliasResolver: { child.aliasResolver(aliasResolver($0)) },
                originatesFromMergingProcess: true
            )
        }

        private func mergedAllRulesWrapped(with child: Self) -> [ConfigurationRuleWrapper] {
            let mainConfigSet = Set(allRulesWrapped.map(HashableConfigurationRuleWrapperWrapper.init))
            let childConfigSet = Set(child.allRulesWrapped.map(HashableConfigurationRuleWrapperWrapper.init))
            let childConfigRulesWithConfig = childConfigSet
                .filter(\.configurationRuleWrapper.initializedWithNonEmptyConfiguration)

            let rulesUniqueToChildConfig = childConfigSet.subtracting(mainConfigSet)
            return childConfigRulesWithConfig // Include, if rule is configured in child
                .union(rulesUniqueToChildConfig) // Include, if rule is in child config only
                .union(mainConfigSet) // Use configurations from parent for remaining rules
                .map(\.configurationRuleWrapper)
        }

        private func mergedCustomRules(newAllRulesWrapped: [ConfigurationRuleWrapper],
                                       with child: Self) -> [ConfigurationRuleWrapper] {
            guard
                let parentCustomRulesRule = (allRulesWrapped.first { $0.rule is CustomRules })?.rule
                    as? CustomRules,
                let childCustomRulesRule = (child.allRulesWrapped.first { $0.rule is CustomRules })?.rule
                    as? CustomRules
            else {
                // Merging is only needed if both parent & child have a custom rules rule
                return newAllRulesWrapped
            }

            // Create new custom rules rule, prioritizing child custom rules
            var configuration = CustomRulesConfiguration()
            configuration.customRuleConfigurations = childCustomRulesRule.configuration.customRuleConfigurations
                + parentCustomRulesRule.configuration.customRuleConfigurations.filter { parentConfig in
                    !childCustomRulesRule.configuration.customRuleConfigurations.contains { childConfig in
                        childConfig.identifier == parentConfig.identifier
                    }
                }
            var newCustomRulesRule = CustomRules()
            newCustomRulesRule.configuration = configuration

            return newAllRulesWrapped.filter { !($0.rule is CustomRules) } + [(newCustomRulesRule, true)]
        }

        private func mergeDefaultMode(
            newAllRulesWrapped: [ConfigurationRuleWrapper],
            child: Self,
            childDisabled: Set<String>,
            childOptIn: Set<String>,
            validRuleIdentifiers: Set<String>
        ) -> RulesMode {
            let childDisabled = Self.validate(ruleIds: childDisabled, valid: validRuleIdentifiers)
            let childOptIn = Self.validate(optInRuleIds: childOptIn, valid: validRuleIdentifiers)

            switch mode { // Switch parent's mode. Child is in default mode.
            case var .default(disabled, optIn):
                disabled = Self.validate(ruleIds: disabled, valid: validRuleIdentifiers)
                optIn = Self.validate(optInRuleIds: optIn, valid: validRuleIdentifiers)

                // Only use parent disabled / optIn if child config doesn't tell the opposite
                return .default(
                    disabled: Set(childDisabled).union(Set(disabled.filter { !childOptIn.contains($0) })),
                    optIn: Set(childOptIn).union(Set(optIn.filter { !childDisabled.contains($0) }))
                        .filter {
                            isOptInRule($0, allRulesWrapped: newAllRulesWrapped)
                        }
                )

            case var .only(onlyRules):
                // Also add identifiers of child custom rules iff the custom_rules rule is enabled
                // (parent custom rules are already added)
                if (onlyRules.contains { $0 == CustomRules.description.identifier }) {
                    if let childCustomRulesRule = (child.allRulesWrapped.first { $0.rule is CustomRules })?.rule
                        as? CustomRules {
                        onlyRules = onlyRules.union(
                            Set(
                                childCustomRulesRule.configuration.customRuleConfigurations.map(\.identifier)
                            )
                        )
                    }
                }

                onlyRules = Self.validate(ruleIds: onlyRules, valid: validRuleIdentifiers)

                // Allow parent only rules that weren't disabled via the child config
                // & opt-ins from the child config
                return .only(Set(
                    childOptIn.union(onlyRules).filter { !childDisabled.contains($0) }
                ))

            case .allEnabled:
                // Opt-in to every rule that isn't disabled via child config
                return .default(
                    disabled: childDisabled
                        .filter {
                            !isOptInRule($0, allRulesWrapped: newAllRulesWrapped)
                        },
                    optIn: Set(newAllRulesWrapped.map { type(of: $0.rule).description.identifier }
                        .filter {
                            !childDisabled.contains($0)
                            && isOptInRule($0, allRulesWrapped: newAllRulesWrapped)
                        }
                    )
                )
            }
        }

        // MARK: Helpers
        private func isOptInRule(
            _ identifier: String, allRulesWrapped: [ConfigurationRuleWrapper]
        ) -> Bool {
            if let cachedIsOptInRule = Self.isOptInRuleCache[identifier] {
                return cachedIsOptInRule
            }

            let isOptInRule = allRulesWrapped
                .first { type(of: $0.rule).description.identifier == identifier }?.rule is any OptInRule
            Self.isOptInRuleCache[identifier] = isOptInRule
            return isOptInRule
        }
    }
}
