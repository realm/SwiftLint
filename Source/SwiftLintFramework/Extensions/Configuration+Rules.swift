import Foundation

internal extension Configuration {
    class RulesWrapper {
        // MARK: - Properties
        private static var isOptInRuleCache: [String: Bool] = [:]

        public let allRulesWrapped: [ConfigurationRuleWrapper]
        private let mode: RulesMode
        private let aliasResolver: (String) -> String

        private var invalidRuleIdsWarnedAbout: Set<String> = []
        private var validRuleIdentifiers: Set<String> {
            let regularRuleIdentifiers = allRulesWrapped.map { type(of: $0.rule).description.identifier }
            let configurationCustomRulesIdentifiers =
                (allRulesWrapped.first { $0.rule is CustomRules }?.rule as? CustomRules)?
                    .configuration.customRuleConfigurations.map { $0.identifier } ?? []
            return Set(regularRuleIdentifiers + configurationCustomRulesIdentifiers)
        }

        private var cachedResultingRules: [Rule]?
        private let resultingRulesLock = NSLock()

        /// All rules enabled in this configuration,
        /// derived from rule mode (whitelist / optIn - disabled) & existing rules
        var resultingRules: [Rule] {
            // Lock for thread-safety (that's also why this is not a lazy var)
            resultingRulesLock.lock()
            defer { resultingRulesLock.unlock() }

            // Return existing value if there
            if let cachedResultingRules = cachedResultingRules { return cachedResultingRules }

            // Calculate value
            var resultingRules = [Rule]()
            switch mode {
            case .allEnabled:
                resultingRules = allRulesWrapped.map { $0.rule }

            case var .whitelisted(whitelistedRuleIdentifiers):
                whitelistedRuleIdentifiers = validate(ruleIds: whitelistedRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWrapped.filter { tuple in
                    whitelistedRuleIdentifiers.contains(type(of: tuple.rule).description.identifier)
                }.map { $0.rule }

            case var .default(disabledRuleIdentifiers, optInRuleIdentifiers):
                disabledRuleIdentifiers = validate(ruleIds: disabledRuleIdentifiers, valid: validRuleIdentifiers)
                optInRuleIdentifiers = validate(ruleIds: optInRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWrapped.filter { tuple in
                    let id = type(of: tuple.rule).description.identifier
                    return !disabledRuleIdentifiers.contains(id)
                        && (!(tuple.rule is OptInRule) || optInRuleIdentifiers.contains(id))
                }.map { $0.rule }
            }

            // Sort by name
            resultingRules = resultingRules.sorted {
                type(of: $0).description.identifier < type(of: $1).description.identifier
            }

            // Store & return
            cachedResultingRules = resultingRules
            return resultingRules
        }

        lazy var disabledRuleIdentifiers: [String] = {
            switch mode {
            case let .default(disabled, _):
                return validate(ruleIds: disabled, valid: validRuleIdentifiers, silent: true)
                    .sorted(by: <)

            case let .whitelisted(whitelisted):
                return validate(
                    ruleIds: Set(allRulesWrapped
                        .map { type(of: $0.rule).description.identifier }
                        .filter { !whitelisted.contains($0) }),
                    valid: validRuleIdentifiers,
                    silent: true
                ).sorted(by: <)

            case .allEnabled:
                return []
            }
        }()

        // MARK: - Initializers
        init(
            mode: RulesMode,
            allRulesWrapped: [ConfigurationRuleWrapper],
            aliasResolver: @escaping (String) -> String
        ) {
            self.allRulesWrapped = allRulesWrapped
            self.aliasResolver = aliasResolver
            self.mode = mode.applied(aliasResolver: aliasResolver)
        }

        // MARK: - Methods: Validation
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
            case let .default(childDisabled, childOptIn):
                newMode = mergeDefaultMode(
                    newAllRulesWrapped: newAllRulesWrapped,
                    child: child,
                    childDisabled: childDisabled,
                    childOptIn: childOptIn
                )

            case var .whitelisted(childWhitelisted):
                childWhitelisted = child.validate(ruleIds: childWhitelisted, valid: validRuleIdentifiers)

                // Always use the child whitelist
                newMode = .whitelisted(childWhitelisted)

            case .allEnabled:
                // Always use .allEnabled mode
                newMode = .allEnabled
            }

            // Assemble & return merged Rules
            return RulesWrapper(
                mode: newMode,
                allRulesWrapped: merged(
                    customRules: newAllRulesWrapped,
                    mode: newMode,
                    with: child
                ),
                aliasResolver: { child.aliasResolver(self.aliasResolver($0)) }
            )
        }

        private func mergedAllRulesWrapped(with sub: RulesWrapper) -> [ConfigurationRuleWrapper] {
            let mainConfigSet = Set(allRulesWrapped.map(HashableConfigurationRuleWrapperWrapper.init))
            let childConfigSet = Set(sub.allRulesWrapped.map(HashableConfigurationRuleWrapperWrapper.init))
            let childConfigRulesWithConfig = childConfigSet.filter {
                $0.configurationRuleWrapper.initializedWithNonEmptyConfiguration
            }

            let rulesUniqueToChildConfig = childConfigSet.subtracting(mainConfigSet)
            return childConfigRulesWithConfig // Include, if rule is configured in child
                .union(rulesUniqueToChildConfig) // Include, if rule is in child config only
                .union(mainConfigSet) // Use configurations from parent for remaining rules
                .map { $0.configurationRuleWrapper }
        }

        private func merged(
            customRules rules: [ConfigurationRuleWrapper], mode: RulesMode, with child: RulesWrapper
        ) -> [ConfigurationRuleWrapper] {
            guard
                let customRulesRule = (allRulesWrapped.first {
                    $0.rule is CustomRules
                })?.rule as? CustomRules,
                let childCustomRulesRule = (child.allRulesWrapped.first {
                    $0.rule is CustomRules
                })?.rule as? CustomRules
            else {
                // Merging is only needed if both parent & child have a custom rules rule
                return rules
            }

            let customRulesFilter: (RegexConfiguration) -> (Bool)
            switch mode {
            case .allEnabled:
                customRulesFilter = { _ in true }

            case let .whitelisted(whitelistedRules):
                customRulesFilter = { whitelistedRules.contains($0.identifier) }

            case let .default(disabledRules, _):
                customRulesFilter = { !disabledRules.contains($0.identifier) }
            }

            var configuration = CustomRulesConfiguration()
            configuration.customRuleConfigurations = Set(customRulesRule.configuration.customRuleConfigurations)
                .union(Set(childCustomRulesRule.configuration.customRuleConfigurations))
                .filter(customRulesFilter)

            var customRules = CustomRules()
            customRules.configuration = configuration

            return rules.filter { !($0.rule is CustomRules) } + [(customRules, true)]
        }

        private func mergeDefaultMode(
            newAllRulesWrapped: [ConfigurationRuleWrapper],
            child: RulesWrapper,
            childDisabled: Set<String>,
            childOptIn: Set<String>
        ) -> RulesMode {
            let childDisabled = child.validate(ruleIds: childDisabled, valid: validRuleIdentifiers)
            let childOptIn = child.validate(ruleIds: childOptIn, valid: validRuleIdentifiers)

            switch mode {
            case var .default(disabled, optIn):
                disabled = validate(ruleIds: disabled, valid: validRuleIdentifiers)
                optIn = child.validate(ruleIds: optIn, valid: validRuleIdentifiers)

                // Only use parent disabled / optIn if child config doesn't tell the opposite
                return .default(
                    disabled: Set(childDisabled).union(Set(disabled.filter { !childOptIn.contains($0) }))
                        .filter {
                            // (. != true) means (. == false) || (. == nil)
                            isOptInRule($0, allRulesWrapped: newAllRulesWrapped) != true
                        },
                    optIn: Set(childOptIn).union(Set(optIn.filter { !childDisabled.contains($0) }))
                        .filter {
                            // (. != false) means (. == true) || (. == nil)
                            isOptInRule($0, allRulesWrapped: newAllRulesWrapped) != false
                        }
                )

            case var .whitelisted(whitelisted):
                whitelisted = validate(ruleIds: whitelisted, valid: validRuleIdentifiers)

                // Allow parent whitelist rules that weren't disabled via the child config
                // & opt-ins from the child config
                return .whitelisted(Set(
                    childOptIn + whitelisted.filter { !childDisabled.contains($0) }
                ))

            case .allEnabled:
                // Opt-in to every rule that isn't disabled via child config
                return .default(
                    disabled: childDisabled
                        .filter {
                            isOptInRule($0, allRulesWrapped: newAllRulesWrapped) == false
                        },
                    optIn: Set(newAllRulesWrapped.map { type(of: $0.rule).description.identifier }
                        .filter {
                            !childDisabled.contains($0)
                            && isOptInRule($0, allRulesWrapped: newAllRulesWrapped) == true
                        }
                    )
                )
            }
        }

        // MARK: Helpers
        private func isOptInRule(
            _ identifier: String, allRulesWrapped: [ConfigurationRuleWrapper]
        ) -> Bool? {
            if let cachedIsOptInRule = RulesWrapper.isOptInRuleCache[identifier] {
                return cachedIsOptInRule
            }

            let isOptInRule = allRulesWrapped
                .first { type(of: $0.rule).description.identifier == identifier }?.rule is OptInRule
            RulesWrapper.isOptInRuleCache[identifier] = isOptInRule
            return isOptInRule
        }
    }
}
