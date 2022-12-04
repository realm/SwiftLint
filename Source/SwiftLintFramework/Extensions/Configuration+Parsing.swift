// swiftlint:disable inclusive_language - To ease a migration from the previous `whitelist_rules`

extension Configuration {
    // MARK: - Subtypes
    internal enum Key: String, CaseIterable {
        case cachePath = "cache_path"
        case disabledRules = "disabled_rules"
        case enabledRules = "enabled_rules" // deprecated in favor of optInRules
        case excluded = "excluded"
        case included = "included"
        case optInRules = "opt_in_rules"
        case reporter = "reporter"
        case swiftlintVersion = "swiftlint_version"
        case useNestedConfigs = "use_nested_configs" // deprecated, always enabled
        case warningThreshold = "warning_threshold"
        case onlyRules = "only_rules"
        case whitelistRules = "whitelist_rules" // deprecated in favor of onlyRules
        case indentation = "indentation"
        case analyzerRules = "analyzer_rules"
        case allowZeroLintableFiles = "allow_zero_lintable_files"
        case childConfig = "child_config"
        case parentConfig = "parent_config"
        case remoteConfigTimeout = "remote_timeout"
        case remoteConfigTimeoutIfCached = "remote_timeout_if_cached"
    }

    // MARK: - Properties
    private static let validGlobalKeys: Set<String> = Set(Key.allCases.map { $0.rawValue })

    // MARK: - Initializers
    /// Creates a Configuration value based on the specified parameters.
    ///
    /// - parameter dict:                   The untyped dictionary to serve as the input for this typed configuration.
    ///                                     Typically generated from a YAML-formatted file.
    /// - parameter ruleList:               The list of rules to be available to this configuration.
    /// - parameter enableAllRules:         Whether all rules from `ruleList` should be enabled, regardless of the
    ///                                     settings in `dict`.
    /// - parameter cachePath:              The location of the persisted cache on disk.
    public init(
        dict: [String: Any],
        ruleList: RuleList = primaryRuleList,
        enableAllRules: Bool = false,
        cachePath: String? = nil
    ) throws {
        func defaultStringArray(_ object: Any?) -> [String] { return [String].array(of: object) ?? [] }

        // Use either the new 'opt_in_rules' or fallback to the deprecated 'enabled_rules'
        let optInRules = defaultStringArray(dict[Key.optInRules.rawValue] ?? dict[Key.enabledRules.rawValue])
        let disabledRules = defaultStringArray(dict[Key.disabledRules.rawValue])

        // Use either the new 'only_rules' or fallback to the deprecated 'whitelist_rules'
        let onlyRules = defaultStringArray(dict[Key.onlyRules.rawValue] ?? dict[Key.whitelistRules.rawValue])
        let analyzerRules = defaultStringArray(dict[Key.analyzerRules.rawValue])

        Self.warnAboutInvalidKeys(configurationDictionary: dict, ruleList: ruleList)
        Self.warnAboutDeprecations(
            configurationDictionary: dict, disabledRules: disabledRules,
            optInRules: optInRules, onlyRules: onlyRules, ruleList: ruleList
        )
        Self.warnAboutMisplacedAnalyzerRules(optInRules: optInRules, ruleList: ruleList)

        let allRulesWrapped: [ConfigurationRuleWrapper]
        do {
            allRulesWrapped = try ruleList.allRulesWrapped(configurationDict: dict)
        } catch let RuleListError.duplicatedConfigurations(ruleType) {
            let aliases = ruleType.description.deprecatedAliases.map { "'\($0)'" }.joined(separator: ", ")
            let identifier = ruleType.description.identifier
            throw ConfigurationError.generic(
                "Multiple configurations found for '\(identifier)'. Check for any aliases: \(aliases)."
            )
        }

        let rulesMode = try RulesMode(
            enableAllRules: enableAllRules,
            onlyRules: onlyRules,
            optInRules: optInRules,
            disabledRules: disabledRules,
            analyzerRules: analyzerRules
        )

        Self.validateConfiguredRulesAreEnabled(
            configurationDictionary: dict, ruleList: ruleList, rulesMode: rulesMode
        )

        self.init(
            rulesMode: rulesMode,
            allRulesWrapped: allRulesWrapped,
            ruleList: ruleList,
            includedPaths: defaultStringArray(dict[Key.included.rawValue]),
            excludedPaths: defaultStringArray(dict[Key.excluded.rawValue]),
            indentation: Self.getIndentationLogIfInvalid(from: dict),
            warningThreshold: dict[Key.warningThreshold.rawValue] as? Int,
            reporter: dict[Key.reporter.rawValue] as? String ?? XcodeReporter.identifier,
            cachePath: cachePath ?? dict[Key.cachePath.rawValue] as? String,
            pinnedVersion: dict[Key.swiftlintVersion.rawValue].map { ($0 as? String) ?? String(describing: $0) },
            allowZeroLintableFiles: dict[Key.allowZeroLintableFiles.rawValue] as? Bool ?? false
        )
    }

    // MARK: - Methods: Validations
    private static func validKeys(ruleList: RuleList) -> Set<String> {
        return validGlobalKeys.union(ruleList.allValidIdentifiers())
    }

    private static func getIndentationLogIfInvalid(from dict: [String: Any]) -> IndentationStyle {
        if let rawIndentation = dict[Key.indentation.rawValue] {
            if let indentationStyle = Self.IndentationStyle(rawIndentation) {
                return indentationStyle
            }

            queuedPrintError("Invalid configuration for '\(Key.indentation)'. Falling back to default.")
            return .default
        }

        return .default
    }

    private static func warnAboutDeprecations(
        configurationDictionary dict: [String: Any],
        disabledRules: [String] = [],
        optInRules: [String] = [],
        onlyRules: [String] = [],
        ruleList: RuleList
    ) {
        // Deprecation warning for "enabled_rules"
        if dict[Key.enabledRules.rawValue] != nil {
            queuedPrintError("warning: '\(Key.enabledRules.rawValue)' has been renamed to " +
                "'\(Key.optInRules.rawValue)' and will be completely removed in a " +
                "future release.")
        }

        // Deprecation warning for "use_nested_configs"
        if dict[Key.useNestedConfigs.rawValue] != nil {
            queuedPrintError("warning: Support for '\(Key.useNestedConfigs.rawValue)' has " +
                "been deprecated and its value is now ignored. Nested configuration files are " +
                "now always considered.")
        }

        // Deprecation warning for "whitelist_rules"
        if dict[Key.whitelistRules.rawValue] != nil {
            queuedPrintError("'\(Key.whitelistRules.rawValue)' has been renamed to " +
                "'\(Key.onlyRules.rawValue)' and will be completely removed in a " +
                "future release.")
        }

        // Deprecation warning for rules
        let deprecatedRulesIdentifiers = ruleList.list.flatMap { identifier, rule -> [(String, String)] in
            return rule.description.deprecatedAliases.map { ($0, identifier) }
        }

        let userProvidedRuleIDs = Set(disabledRules + optInRules + onlyRules)
        let deprecatedUsages = deprecatedRulesIdentifiers.filter { deprecatedIdentifier, _ in
            return dict[deprecatedIdentifier] != nil || userProvidedRuleIDs.contains(deprecatedIdentifier)
        }

        for (deprecatedIdentifier, identifier) in deprecatedUsages {
            queuedPrintError(
                "warning: '\(deprecatedIdentifier)' rule has been renamed to '\(identifier)' and will be "
                    + "completely removed in a future release."
            )
        }
    }

    private static func warnAboutInvalidKeys(configurationDictionary dict: [String: Any], ruleList: RuleList) {
        // Log an error when supplying invalid keys in the configuration dictionary
        let invalidKeys = Set(dict.keys).subtracting(validKeys(ruleList: ruleList))
        if invalidKeys.isNotEmpty {
            queuedPrintError("warning: Configuration contains invalid keys:\n\(invalidKeys)")
        }
    }

    private static func validateConfiguredRulesAreEnabled(
        configurationDictionary dict: [String: Any],
        ruleList: RuleList,
        rulesMode: RulesMode
    ) {
        for key in dict.keys where !validGlobalKeys.contains(key) {
            guard let identifier = ruleList.identifier(for: key),
                let rule = ruleList.list[identifier] else {
                    continue
            }

            let message = "warning: Found a configuration for '\(identifier)' rule"

            switch rulesMode {
            case .allEnabled:
                return

            case .only(let onlyRules):
                if Set(onlyRules).isDisjoint(with: rule.description.allIdentifiers) {
                    queuedPrintError("\(message), but it is not present on " +
                        "'\(Key.onlyRules.rawValue)'.")
                }

            case let .default(disabled: disabledRules, optIn: optInRules):
                if rule is OptInRule.Type, Set(optInRules).isDisjoint(with: rule.description.allIdentifiers) {
                    queuedPrintError("\(message), but it is not enabled on " +
                        "'\(Key.optInRules.rawValue)'.")
                } else if Set(disabledRules).isSuperset(of: rule.description.allIdentifiers) {
                    queuedPrintError("\(message), but it is disabled on " +
                        "'\(Key.disabledRules.rawValue)'.")
                }
            }
        }
    }

    private static func warnAboutMisplacedAnalyzerRules(optInRules: [String], ruleList: RuleList) {
        let analyzerRules = ruleList.list
            .filter { $0.value.self is AnalyzerRule.Type }
            .map(\.key)
        Set(analyzerRules).intersection(optInRules)
            .sorted()
            .forEach {
                queuedPrintError("""
                    warning: '\($0)' should be listed in the 'analyzer_rules' configuration section \
                    for more clarity as it is only run by 'swiftlint analyze'
                    """)
            }
    }
}
