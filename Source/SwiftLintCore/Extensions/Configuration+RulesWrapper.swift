import Foundation

internal extension Configuration {
    class RulesWrapper {
        // MARK: - Properties
        private static var isOptInRuleCache: [String: Bool] = [:]

        let allRulesWrapped: [ConfigurationRuleWrapper]
        internal let mode: RulesMode
        private let aliasResolver: (String) -> String

        private var invalidRuleIdsWarnedAbout: Set<String> = []
        private var validRuleIdentifiers: Set<String> {
            let regularRuleIdentifiers = allRulesWrapped.map { type(of: $0.rule).identifier }
            let configurationCustomRulesIdentifiers =
                (allRulesWrapped.first { $0.rule is CustomRules }?.rule as? CustomRules)?.customRuleIdentifiers ?? []
            return Set(regularRuleIdentifiers + configurationCustomRulesIdentifiers)
        }

        private var cachedResultingRules: [any Rule]?
        private let resultingRulesLock = NSLock()

        /// All rules enabled in this configuration,
        /// derived from rule mode (only / optIn - disabled) & existing rules
        var resultingRules: [any Rule] {
            // Lock for thread-safety (that's also why this is not a lazy var)
            resultingRulesLock.lock()
            defer { resultingRulesLock.unlock() }

            // Return existing value if it's available
            if let cachedResultingRules { return cachedResultingRules }

            // Calculate value
            let customRulesFilter: (RegexConfiguration<CustomRules>) -> (Bool)
            var resultingRules = [any Rule]()
            switch mode {
            case .allCommandLine:
                customRulesFilter = { _ in true }
                resultingRules = allRulesWrapped.map(\.rule)

            case let .onlyConfiguration(onlyRulesRuleIdentifiers), let .onlyCommandLine(onlyRulesRuleIdentifiers):
                customRulesFilter = { onlyRulesRuleIdentifiers.contains($0.identifier) }
                let onlyRulesRuleIdentifiers = validate(ruleIds: onlyRulesRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWrapped.filter { tuple in
                    onlyRulesRuleIdentifiers.contains(type(of: tuple.rule).identifier)
                }.map(\.rule)

            case var .defaultConfiguration(disabledRuleIdentifiers, optInRuleIdentifiers):
                customRulesFilter = { !disabledRuleIdentifiers.contains($0.identifier) }
                disabledRuleIdentifiers = validate(ruleIds: disabledRuleIdentifiers, valid: validRuleIdentifiers)
                optInRuleIdentifiers = validate(optInRuleIds: optInRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWrapped.filter { tuple in
                    let id = type(of: tuple.rule).identifier
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
                type(of: $0).identifier < type(of: $1).identifier
            }

            // Store & return
            cachedResultingRules = resultingRules
            return resultingRules
        }

        lazy var disabledRuleIdentifiers: [String] = {
            switch mode {
            case let .defaultConfiguration(disabled, _):
                return validate(ruleIds: disabled, valid: validRuleIdentifiers, silent: true)
                    .sorted(by: <)

            case let .onlyConfiguration(onlyRules), let .onlyCommandLine(onlyRules):
                return validate(
                    ruleIds: Set(allRulesWrapped
                        .map { type(of: $0.rule).identifier }
                        .filter { !onlyRules.contains($0) }),
                    valid: validRuleIdentifiers,
                    silent: true
                ).sorted(by: <)

            case .allCommandLine:
                return []
            }
        }()

        // MARK: - Initializers
        init(
            mode: RulesMode,
            allRulesWrapped: [ConfigurationRuleWrapper],
            aliasResolver: @escaping (String) -> String,
            originatesFromMergingProcess: Bool = false
        ) {
            self.allRulesWrapped = allRulesWrapped
            self.aliasResolver = aliasResolver
            let mode = mode.applied(aliasResolver: aliasResolver)

            // If this instance originates from a merging process, some custom rules may be treated as not activated
            // Otherwise, custom rules should be treated as implicitly activated
            self.mode = originatesFromMergingProcess
                ? mode
                : mode.activateCustomRuleIdentifiers(allRulesWrapped: allRulesWrapped)
        }

        // MARK: - Methods: Validation
        private func validate(optInRuleIds: Set<String>, valid: Set<String>) -> Set<String> {
            validate(ruleIds: optInRuleIds, valid: valid.union([RuleIdentifier.all.stringRepresentation]))
        }

        private func validate(ruleIds: Set<String>, valid: Set<String>, silent: Bool = false) -> Set<String> {
            // Process invalid rule identifiers
            if !silent {
                let invalidRuleIdentifiers = ruleIds.subtracting(valid)
                if !invalidRuleIdentifiers.isEmpty {
                    for invalidRuleIdentifier in invalidRuleIdentifiers.subtracting(invalidRuleIdsWarnedAbout) {
                        invalidRuleIdsWarnedAbout.insert(invalidRuleIdentifier)
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
        func merged(with child: RulesWrapper) -> RulesWrapper {
            // Merge allRulesWrapped
            let newAllRulesWrapped = mergedAllRulesWrapped(with: child)

            // Merge mode
            let validRuleIdentifiers = self.validRuleIdentifiers.union(child.validRuleIdentifiers)
            let newMode: RulesMode
            switch child.mode {
            case let .defaultConfiguration(childDisabled, childOptIn):
                newMode = mergeDefaultMode(
                    newAllRulesWrapped: newAllRulesWrapped,
                    child: child,
                    childDisabled: childDisabled,
                    childOptIn: childOptIn,
                    validRuleIdentifiers: validRuleIdentifiers
                )

            case let .onlyConfiguration(childOnlyRules):
                // Use the child only rules, unless the parent is onlyRule
                switch mode {
                case let .onlyCommandLine(onlyRules):
                    newMode = .onlyCommandLine(onlyRules)
                default:
                    newMode = .onlyConfiguration(childOnlyRules)
                }
            case let .onlyCommandLine(onlyRules):
                // Always use the only rule
                newMode = .onlyCommandLine(onlyRules)

            case .allCommandLine:
                // Always use .allEnabled mode
                newMode = .allCommandLine
            }

            // Assemble & return merged rules
            return RulesWrapper(
                mode: newMode,
                allRulesWrapped: mergedCustomRules(newAllRulesWrapped: newAllRulesWrapped, with: child),
                aliasResolver: { child.aliasResolver(self.aliasResolver($0)) },
                originatesFromMergingProcess: true
            )
        }

        private func mergedAllRulesWrapped(with child: RulesWrapper) -> [ConfigurationRuleWrapper] {
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

        private func mergedCustomRules(
            newAllRulesWrapped: [ConfigurationRuleWrapper], with child: RulesWrapper
        ) -> [ConfigurationRuleWrapper] {
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
            child: RulesWrapper,
            childDisabled: Set<String>,
            childOptIn: Set<String>,
            validRuleIdentifiers: Set<String>
        ) -> RulesMode {
            let childDisabled = child.validate(ruleIds: childDisabled, valid: validRuleIdentifiers)
            let childOptIn = child.validate(optInRuleIds: childOptIn, valid: validRuleIdentifiers)

            switch mode { // Switch parent's mode. Child is in default mode.
            case var .defaultConfiguration(disabled, optIn):
                disabled = validate(ruleIds: disabled, valid: validRuleIdentifiers)
                optIn = child.validate(optInRuleIds: optIn, valid: validRuleIdentifiers)

                // Only use parent disabled / optIn if child config doesn't tell the opposite
                return .defaultConfiguration(
                    disabled: Set(childDisabled).union(Set(disabled.filter { !childOptIn.contains($0) })),
                    optIn: Set(childOptIn).union(Set(optIn.filter { !childDisabled.contains($0) }))
                        .filter {
                            isOptInRule($0, allRulesWrapped: newAllRulesWrapped)
                        }
                )

            case var .onlyConfiguration(onlyRules):
                // Also add identifiers of child custom rules iff the custom_rules rule is enabled
                // (parent custom rules are already added)
                if (onlyRules.contains { $0 == CustomRules.identifier }) {
                    if let childCustomRulesRule = (child.allRulesWrapped.first { $0.rule is CustomRules })?.rule
                        as? CustomRules {
                        onlyRules = onlyRules.union(
                            Set(
                                childCustomRulesRule.customRuleIdentifiers
                            )
                        )
                    }
                }

                onlyRules = validate(ruleIds: onlyRules, valid: validRuleIdentifiers)

                // Allow parent only rules that weren't disabled via the child config
                // & opt-ins from the child config
                return .onlyConfiguration(Set(
                    childOptIn.union(onlyRules).filter { !childDisabled.contains($0) }
                ))

            case let .onlyCommandLine(onlyRules):
                // Like .allEnabled, rules can be disabled in a child config
                return .onlyCommandLine(onlyRules.filter { !childDisabled.contains($0) })

            case .allCommandLine:
                // Opt-in to every rule that isn't disabled via child config
                return .defaultConfiguration(
                    disabled: childDisabled
                        .filter {
                            !isOptInRule($0, allRulesWrapped: newAllRulesWrapped)
                        },
                    optIn: Set(newAllRulesWrapped.map { type(of: $0.rule).identifier }
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
                .first { type(of: $0.rule).identifier == identifier }?.rule is any OptInRule
            Self.isOptInRuleCache[identifier] = isOptInRule
            return isOptInRule
        }
    }
}
