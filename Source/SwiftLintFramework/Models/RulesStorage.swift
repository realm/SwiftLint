import Foundation

public class RulesStorage {
    // MARK: - Subtypes
    public enum Mode {
        case `default`(disabled: Set<String>, optIn: Set<String>)
        case whitelisted(Set<String>)
        case allEnabled

        init(
            enableAllRules: Bool,
            whitelistRules: [String],
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
            } else if !whitelistRules.isEmpty {
                if !disabledRules.isEmpty || !optInRules.isEmpty {
                    throw ConfigurationError.generic(
                        "'\(Configuration.Key.disabledRules.rawValue)' or " +
                            "'\(Configuration.Key.optInRules.rawValue)' cannot be used in combination " +
                        "with '\(Configuration.Key.whitelistRules.rawValue)'"
                    )
                }

                warnAboutDuplicates(in: whitelistRules + analyzerRules)
                self = .whitelisted(Set(whitelistRules + analyzerRules))
            } else {
                warnAboutDuplicates(in: disabledRules)
                warnAboutDuplicates(in: optInRules + analyzerRules)
                self = .default(disabled: Set(disabledRules), optIn: Set(optInRules + analyzerRules))
            }
        }

        func applied(aliasResolver: (String) -> String) -> Mode {
            switch self {
            case let .default(disabled, optIn):
                return .default(
                    disabled: Set(disabled.map(aliasResolver)),
                    optIn: Set(optIn.map(aliasResolver))
                )

            case let .whitelisted(whitelisted):
                return .whitelisted(Set(whitelisted.map(aliasResolver)))

            case .allEnabled:
                return .allEnabled
            }
        }
    }

    fileprivate struct HashableRuleWrapper: Hashable {
        fileprivate let rule: Rule

        fileprivate static func == (lhs: HashableRuleWrapper, rhs: HashableRuleWrapper) -> Bool {
            // Only use identifier for equality check (not taking config into account)
            return type(of: lhs.rule).description.identifier == type(of: rhs.rule).description.identifier
        }

        fileprivate func hash(into hasher: inout Hasher) {
            hasher.combine(type(of: rule).description.identifier)
        }
    }

    // MARK: - Properties
    private static var isOptInRuleCache: [String: Bool] = [:]

    public let allRulesWithConfigurations: [Rule]
    private let mode: Mode
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

    /// All rules enabled in this configuration, derived from rule mode (whitelist / optIn - disabled) & existing rules
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
    init(mode: Mode, allRulesWithConfigurations: [Rule], aliasResolver: @escaping (String) -> String) {
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
    internal func merged(with sub: RulesStorage) -> RulesStorage {
        // Merge allRulesWithConfigurations
        let newAllRulesWithConfigurations = mergedAllRulesWithConfigurations(with: sub)

        // Merge mode
        let validRuleIdentifiers = self.validRuleIdentifiers.union(sub.validRuleIdentifiers)
        let newMode: Mode
        switch sub.mode {
        case var .default(subDisabled, subOptIn):
            subDisabled = sub.validate(ruleIds: subDisabled, valid: validRuleIdentifiers)
            subOptIn = sub.validate(ruleIds: subOptIn, valid: validRuleIdentifiers)

            switch mode {
            case var .default(disabled, optIn):
                disabled = validate(ruleIds: disabled, valid: validRuleIdentifiers)
                optIn = sub.validate(ruleIds: optIn, valid: validRuleIdentifiers)

                // Only use parent disabled / optIn if sub config doesn't tell the opposite
                newMode = .default(
                    disabled: Set(subDisabled).union(Set(disabled.filter { !subOptIn.contains($0) }))
                        // (. != true) means (. == false) || (. == nil)
                        .filter { isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) != true },
                    optIn: Set(subOptIn).union(Set(optIn.filter { !subDisabled.contains($0) }))
                        // (. != false) means (. == true) || (. == nil)
                        .filter { isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) != false }
                )

            case var .whitelisted(whitelisted):
                whitelisted = validate(ruleIds: whitelisted, valid: validRuleIdentifiers)

                // Allow parent whitelist rules that weren't disabled via the sub config & opt-ins from the sub config
                newMode = .whitelisted(Set(
                    subOptIn + whitelisted.filter { !subDisabled.contains($0) }
                ))

            case .allEnabled:
                // Opt-in to every rule that isn't disabled via sub config
                newMode = .default(
                    disabled: subDisabled
                        .filter { isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) == false },
                    optIn: Set(newAllRulesWithConfigurations.map { type(of: $0).description.identifier }
                        .filter {
                            !subDisabled.contains($0)
                                && isOptInRule($0, allRulesWithConfigurations: newAllRulesWithConfigurations) == true
                        }
                    )
                )
            }

        case var .whitelisted(subWhitelisted):
            subWhitelisted = sub.validate(ruleIds: subWhitelisted, valid: validRuleIdentifiers)

            // Always use the sub whitelist
            newMode = .whitelisted(subWhitelisted)

        case .allEnabled:
            // Always use .allEnabled mode
            newMode = .allEnabled
        }

        // Assemble & return merged RulesStorage
        return RulesStorage(
            mode: newMode,
            allRulesWithConfigurations: merged(customRules: newAllRulesWithConfigurations, mode: newMode, with: sub),
            aliasResolver: { sub.aliasResolver(self.aliasResolver($0)) }
        )
    }

    private func mergedAllRulesWithConfigurations(with sub: RulesStorage) -> [Rule] {
        let mainConfigSet = Set(allRulesWithConfigurations.map(HashableRuleWrapper.init))
        let subConfigSet = Set(sub.allRulesWithConfigurations.map(HashableRuleWrapper.init))
        let subConfigRulesWithConfig = subConfigSet.filter { $0.rule.initializedWithNonEmptyConfiguration }
        let rulesUniqueToSubConfig = subConfigSet.subtracting(mainConfigSet)
        return subConfigRulesWithConfig // Include, if rule is configured in sub
            .union(rulesUniqueToSubConfig) // Include, if rule is in sub config only
            .union(mainConfigSet) // Use configurations from parent for remaining rules
            .map { $0.rule }
    }

    private func merged(customRules rules: [Rule], mode: Mode, with sub: RulesStorage) -> [Rule] {
        guard
            let customRulesRule = (allRulesWithConfigurations.first { $0 is CustomRules }) as? CustomRules,
            let subCustomRulesRule = (sub.allRulesWithConfigurations.first { $0 is CustomRules }) as? CustomRules
        else {
            // Merging is only needed if both parent & sub have a custom rules rule
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
            .union(Set(subCustomRulesRule.configuration.customRuleConfigurations))
            .filter(customRulesFilter)

        var customRules = CustomRules()
        customRules.configuration = configuration

        return rules.filter { !($0 is CustomRules) } + [customRules]
    }

    // MARK: Helpers
    private func isOptInRule(_ identifier: String, allRulesWithConfigurations: [Rule]) -> Bool? {
        if let cachedIsOptInRule = RulesStorage.isOptInRuleCache[identifier] {
            return cachedIsOptInRule
        }

        let isOptInRule = allRulesWithConfigurations
            .first { type(of: $0).description.identifier == identifier } is OptInRule
        RulesStorage.isOptInRuleCache[identifier] = isOptInRule
        return isOptInRule
    }
}
