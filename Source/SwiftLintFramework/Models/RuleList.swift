/// All possible rule list configuration errors.
public enum RuleListError: Error {
    /// The rule list contains more than one configuration for the specified rule.
    case duplicatedConfigurations(rule: Rule.Type)
}

/// A list of available SwiftLint rules.
public struct RuleList {
    /// The rules contained in this list.
    public let list: [String: Rule.Type]
    private let aliases: [String: String]

    // MARK: - Initializers

    /// Creates a `RuleList` by specifying all its rules.
    ///
    /// - parameter rules: The rules to be contained in this list.
    public init(rules: Rule.Type...) {
        self.init(rules: rules)
    }

    /// Creates a `RuleList` by specifying all its rules.
    ///
    /// - parameter rules: The rules to be contained in this list.
    public init(rules: [Rule.Type]) {
        var tmpList = [String: Rule.Type]()
        var tmpAliases = [String: String]()

        for rule in rules {
            let identifier = rule.description.identifier
            tmpList[identifier] = rule
            for alias in rule.description.deprecatedAliases {
                tmpAliases[alias] = identifier
            }
            tmpAliases[identifier] = identifier
        }
        list = tmpList
        aliases = tmpAliases
    }

    // MARK: - Internal

    internal func allRulesWrapped(configurationDict: [String: Any] = [:]) throws -> [ConfigurationRuleWrapper] {
        var rules = [String: ConfigurationRuleWrapper]()

        // Add rules where configuration exists
        for (key, configuration) in configurationDict {
            guard let identifier = identifier(for: key), let ruleType = list[identifier] else { continue }
            guard rules[identifier] == nil else { throw RuleListError.duplicatedConfigurations(rule: ruleType) }
            do {
                let configuredRule = try ruleType.init(configuration: configuration)
                let isConfigured = (configuration as? [String: Any])?.isEmpty == false
                    || ([Any].array(of: configuration))?.isEmpty == false
                rules[identifier] = ConfigurationRuleWrapper(
                    rule: configuredRule,
                    initializedWithNonEmptyConfiguration: isConfigured
                )
            } catch {
                queuedPrintError("Invalid configuration for '\(identifier)'. Falling back to default.")
                rules[identifier] = (ruleType.init(), false)
            }
        }

        // Add remaining rules without configuring them
        for (identifier, ruleType) in list where rules[identifier] == nil {
            rules[identifier] = (ruleType.init(), false)
        }

        return Array(rules.values)
    }

    internal func identifier(for alias: String) -> String? {
        return aliases[alias]
    }

    internal func allValidIdentifiers() -> [String] {
        return list.flatMap { _, rule -> [String] in
            rule.description.allIdentifiers
        }
    }
}

extension RuleList: Equatable {
    public static func == (lhs: RuleList, rhs: RuleList) -> Bool {
        return lhs.list.map { $0.0 } == rhs.list.map { $0.0 }
            && lhs.list.map { $0.1.description } == rhs.list.map { $0.1.description }
            && lhs.aliases == rhs.aliases
    }
}
