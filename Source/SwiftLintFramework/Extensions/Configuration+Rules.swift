import Foundation

public extension Configuration {
    class Rules {
        // MARK: - Properties
        private static var isOptInRuleCache: [String: Bool] = [:]

        public let allRulesWithConfigurations: [Rule]
        private let mode: RulesMode
        private let aliasResolver: (String) -> String

        private var invalidRuleIdsWarnedAbout: Set<String> = []
        private var validRuleIdentifiers: Set<String> {
            let regularRuleIdentifiers = allRulesWithConfigurations.map { type(of: $0).description.identifier }
            let configurationCustomRulesIdentifiers =
                (allRulesWithConfigurations.first { $0 is CustomRules } as? CustomRules)?
                    .configuration.customRuleConfigurations.map { $0.identifier } ?? []
            return Set(regularRuleIdentifiers + configurationCustomRulesIdentifiers)
        }

        private var cachedResultingRules: [Rule]?
        private let resultingRulesLock = NSLock()

        /// All rules enabled in this configuration,
        /// derived from rule mode (whitelist / optIn - disabled) & existing rules
        public var resultingRules: [Rule] {
            // Lock for thread-safety (that's also why this is not a lazy var)
            resultingRulesLock.lock()
            defer { resultingRulesLock.unlock() }

            // Return existing value if there
            if let cachedResultingRules = cachedResultingRules { return cachedResultingRules }

            // Calculate value
            var resultingRules = [Rule]()
            switch mode {
            case .allEnabled:
                resultingRules = allRulesWithConfigurations

            case var .whitelisted(whitelistedRuleIdentifiers):
                whitelistedRuleIdentifiers = validate(ruleIds: whitelistedRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWithConfigurations.filter { rule in
                    whitelistedRuleIdentifiers.contains(type(of: rule).description.identifier)
                }

            case var .default(disabledRuleIdentifiers, optInRuleIdentifiers):
                disabledRuleIdentifiers = validate(ruleIds: disabledRuleIdentifiers, valid: validRuleIdentifiers)
                optInRuleIdentifiers = validate(ruleIds: optInRuleIdentifiers, valid: validRuleIdentifiers)
                resultingRules = allRulesWithConfigurations.filter { rule in
                    let id = type(of: rule).description.identifier
                    return !disabledRuleIdentifiers.contains(id)
                        && (!(rule is OptInRule) || optInRuleIdentifiers.contains(id))
                }
            }

            // Sort by name
            resultingRules = resultingRules.sorted {
                type(of: $0).description.identifier < type(of: $1).description.identifier
            }

            // Store & return
            cachedResultingRules = resultingRules
            return resultingRules
        }

        public lazy var disabledRuleIdentifiers: [String] = {
            switch mode {
            case let .default(disabled, _):
                return validate(ruleIds: disabled, valid: validRuleIdentifiers, silent: true)
                    .sorted(by: <)

            case let .whitelisted(whitelisted):
                return validate(
                    ruleIds: Set(allRulesWithConfigurations
                        .map { type(of: $0).description.identifier }
                        .filter { !whitelisted.contains($0) }),
                    valid: validRuleIdentifiers,
                    silent: true
                ).sorted(by: <)

            case .allEnabled:
                return []
            }
        }()

        // MARK: - Initializers
        init(mode: RulesMode, allRulesWithConfigurations: [Rule], aliasResolver: @escaping (String) -> String) {
            self.allRulesWithConfigurations = allRulesWithConfigurations
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
        internal func merged(with child: Rules) -> Rules {
            // Merge allRulesWithConfigurations
            let newAllRulesWithConfigurations = mergedAllRulesWithConfigurations(with: child)

            // Merge mode
            let validRuleIdentifiers = self.validRuleIdentifiers.union(child.validRuleIdentifiers)
            let newMode: RulesMode
            switch child.mode {
            case let .default(childDisabled, childOptIn):
                newMode = mergeDefaultMode(
                    newAllRulesWithConfigurations: newAllRulesWithConfigurations,
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
            return Rules(
                mode: newMode,
                allRulesWithConfigurations: merged(
                    customRules:
                    newAllRulesWithConfigurations,
                    mode: newMode,
                    with: child
                ),
                aliasResolver: { child.aliasResolver(self.aliasResolver($0)) }
            )
        }

        private func mergedAllRulesWithConfigurations(with sub: Rules) -> [Rule] {
            let mainConfigSet = Set(allRulesWithConfigurations.map(HashableRuleWrapper.init))
            let childConfigSet = Set(sub.allRulesWithConfigurations.map(HashableRuleWrapper.init))
            let childConfigRulesWithConfig = childConfigSet.filter { $0.rule.initializedWithNonEmptyConfiguration }
            let rulesUniqueToChildConfig = childConfigSet.subtracting(mainConfigSet)
            return childConfigRulesWithConfig // Include, if rule is configured in child
                .union(rulesUniqueToChildConfig) // Include, if rule is in child config only
                .union(mainConfigSet) // Use configurations from parent for remaining rules
                .map { $0.rule }
        }

        private func merged(customRules rules: [Rule], mode: RulesMode, with child: Rules) -> [Rule] {
            guard
                let customRulesRule = (allRulesWithConfigurations.first {
                    $0 is CustomRules
                }) as? CustomRules,
                let childCustomRulesRule = (child.allRulesWithConfigurations.first {
                    $0 is CustomRules
                }) as? CustomRules
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

            return rules.filter { !($0 is CustomRules) } + [customRules]
        }

        private func mergeDefaultMode(
            newAllRulesWithConfigurations: [Rule],
            child: Rules,
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
                            isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) != true
                        },
                    optIn: Set(childOptIn).union(Set(optIn.filter { !childDisabled.contains($0) }))
                        .filter {
                            // (. != false) means (. == true) || (. == nil)
                            isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) != false
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
                            isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) == false
                        },
                    optIn: Set(newAllRulesWithConfigurations.map { type(of: $0).description.identifier }
                        .filter {
                            !childDisabled.contains($0)
                            && isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) == true
                        }
                    )
                )
            }
        }

        // MARK: Helpers
        private func isOptInRule(_ identifier: String, allRulesWithConfigurations: [Rule]) -> Bool? {
            if let cachedIsOptInRule = Rules.isOptInRuleCache[identifier] {
                return cachedIsOptInRule
            }

            let isOptInRule = allRulesWithConfigurations
                .first { type(of: $0).description.identifier == identifier } is OptInRule
            Rules.isOptInRuleCache[identifier] = isOptInRule
            return isOptInRule
        }
    }
}
