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
        case warningThreshold = "warning_threshold"
        case onlyRules = "only_rules"
        case indentation = "indentation"
        case analyzerRules = "analyzer_rules"
        case allowZeroLintableFiles = "allow_zero_lintable_files"
        case strict = "strict"
        case baseline = "baseline"
        case writeBaseline = "write_baseline"
        case checkForUpdates = "check_for_updates"
        case childConfig = "child_config"
        case parentConfig = "parent_config"
        case remoteConfigTimeout = "remote_timeout"
        case remoteConfigTimeoutIfCached = "remote_timeout_if_cached"
    }

    // MARK: - Properties
    private static let validGlobalKeys: Set<String> = Set(Key.allCases.map(\.rawValue))

    // MARK: - Initializers
    /// Creates a Configuration value based on the specified parameters.
    ///
    /// - parameter parentConfiguration:    The parent configuration, if any.
    /// - parameter dict:                   The untyped dictionary to serve as the input for this typed configuration.
    ///                                     Typically generated from a YAML-formatted file.
    /// - parameter ruleList:               The list of rules to be available to this configuration.
    /// - parameter enableAllRules:         Whether all rules from `ruleList` should be enabled, regardless of the
    ///                                     settings in `dict`.
    /// - parameter cachePath:              The location of the persisted cache on disk.
    public init(
        parentConfiguration: Configuration? = nil,
        dict: [String: Any],
        ruleList: RuleList = RuleRegistry.shared.list,
        enableAllRules: Bool = false,
        onlyRule: String? = nil,
        cachePath: String? = nil
    ) throws {
        func defaultStringArray(_ object: Any?) -> [String] { [String].array(of: object) ?? [] }

        // Use either the new 'opt_in_rules' or fallback to the deprecated 'enabled_rules'
        let optInRules = defaultStringArray(dict[Key.optInRules.rawValue] ?? dict[Key.enabledRules.rawValue])
        let disabledRules = defaultStringArray(dict[Key.disabledRules.rawValue])

        let onlyRules = defaultStringArray(dict[Key.onlyRules.rawValue])
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
            throw Issue.genericWarning(
                "Multiple configurations found for '\(identifier)'. Check for any aliases: \(aliases)."
            )
        }

        let rulesMode = try RulesMode(
            enableAllRules: enableAllRules,
            onlyRule: onlyRule,
            onlyRules: onlyRules,
            optInRules: optInRules,
            disabledRules: disabledRules,
            analyzerRules: analyzerRules
        )

        if onlyRule == nil {
            Self.validateConfiguredRulesAreEnabled(
                parentConfiguration: parentConfiguration,
                configurationDictionary: dict,
                ruleList: ruleList,
                rulesMode: rulesMode
            )
        }

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
            versionConstraint: dict[Key.swiftlintVersion.rawValue].map { ($0 as? String) ?? String(describing: $0) },
            allowZeroLintableFiles: dict[Key.allowZeroLintableFiles.rawValue] as? Bool ?? false,
            strict: dict[Key.strict.rawValue] as? Bool ?? false,
            baseline: dict[Key.baseline.rawValue] as? String,
            writeBaseline: dict[Key.writeBaseline.rawValue] as? String,
            checkForUpdates: dict[Key.checkForUpdates.rawValue] as? Bool ?? false
        )
    }

    // MARK: - Methods: Validations
    private static func validKeys(ruleList: RuleList) -> Set<String> {
        validGlobalKeys.union(ruleList.allValidIdentifiers())
    }

    private static func getIndentationLogIfInvalid(from dict: [String: Any]) -> IndentationStyle {
        if let rawIndentation = dict[Key.indentation.rawValue] {
            if let indentationStyle = Self.IndentationStyle(rawIndentation) {
                return indentationStyle
            }
            Issue.invalidConfiguration(ruleID: Key.indentation.rawValue).print()
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
            Issue.renamedIdentifier(old: Key.enabledRules.rawValue, new: Key.optInRules.rawValue).print()
        }

        // Deprecation warning for rules
        let deprecatedRulesIdentifiers = ruleList.list.flatMap { identifier, rule -> [(String, String)] in
            rule.description.deprecatedAliases.map { ($0, identifier) }
        }

        let userProvidedRuleIDs = Set(disabledRules + optInRules + onlyRules)
        let deprecatedUsages = deprecatedRulesIdentifiers.filter { deprecatedIdentifier, _ in
            dict[deprecatedIdentifier] != nil || userProvidedRuleIDs.contains(deprecatedIdentifier)
        }

        for (deprecatedIdentifier, identifier) in deprecatedUsages {
            Issue.renamedIdentifier(old: deprecatedIdentifier, new: identifier).print()
        }
    }

    private static func warnAboutInvalidKeys(configurationDictionary dict: [String: Any], ruleList: RuleList) {
        // Log an error when supplying invalid keys in the configuration dictionary
        let invalidKeys = Set(dict.keys).subtracting(validKeys(ruleList: ruleList))
        if invalidKeys.isNotEmpty {
            Issue.invalidRuleIDs(invalidKeys).print()
        }
    }

    private static func validateConfiguredRulesAreEnabled(
        parentConfiguration: Configuration?,
        configurationDictionary dict: [String: Any],
        ruleList: RuleList,
        rulesMode: RulesMode
    ) {
        for key in dict.keys where !validGlobalKeys.contains(key) {
            guard let identifier = ruleList.identifier(for: key),
                let ruleType = ruleList.list[identifier] else {
                    continue
            }

            switch rulesMode {
            case .allEnabled:
                return
            case .only(let onlyRules):
                let issue = validateConfiguredRuleIsEnabled(onlyRules: onlyRules, ruleType: ruleType)
                issue?.print()
            case let .default(disabled: disabledRules, optIn: optInRules):
                let issue = validateConfiguredRuleIsEnabled(
                    parentConfiguration: parentConfiguration,
                    disabledRules: disabledRules,
                    optInRules: optInRules,
                    ruleType: ruleType
                )
                issue?.print()
            }
        }
    }

    static func validateConfiguredRuleIsEnabled(
        parentConfiguration: Configuration?,
        disabledRules: Set<String>,
        optInRules: Set<String>,
        ruleType: any Rule.Type
    ) -> Issue? {
        var enabledInParentRules: Set<String> = []
        var disabledInParentRules: Set<String> = []
        var allEnabledRules: Set<String> = []

        if case .only(let onlyRules) = parentConfiguration?.rulesMode {
            enabledInParentRules = onlyRules
        } else if case .default(let parentDisabledRules, let parentOptInRules) = parentConfiguration?.rulesMode {
            enabledInParentRules = parentOptInRules
            disabledInParentRules = parentDisabledRules
        }
        allEnabledRules = enabledInParentRules
            .subtracting(disabledInParentRules)
            .union(optInRules)
            .subtracting(disabledRules)

        return validateConfiguredRuleIsEnabled(
            parentConfiguration: parentConfiguration,
            enabledInParentRules: enabledInParentRules,
            disabledInParentRules: disabledInParentRules,
            disabledRules: disabledRules,
            optInRules: optInRules,
            allEnabledRules: allEnabledRules,
            ruleType: ruleType
        )
    }

    static func validateConfiguredRuleIsEnabled(
        onlyRules: Set<String>,
        ruleType: any Rule.Type
    ) -> Issue? {
        if onlyRules.isDisjoint(with: ruleType.description.allIdentifiers) {
            return Issue.ruleNotPresentInOnlyRules(ruleID: ruleType.identifier)
        }
        return nil
    }

    // swiftlint:disable:next function_parameter_count
    static func validateConfiguredRuleIsEnabled(
        parentConfiguration: Configuration?,
        enabledInParentRules: Set<String>,
        disabledInParentRules: Set<String>,
        disabledRules: Set<String>,
        optInRules: Set<String>,
        allEnabledRules: Set<String>,
        ruleType: any Rule.Type
    ) -> Issue? {
        if case .allEnabled = parentConfiguration?.rulesMode {
            if disabledRules.contains(ruleType.identifier) {
                return Issue.ruleDisabledInDisabledRules(ruleID: ruleType.identifier)
            }
            return nil
        }

        let allIdentifiers = ruleType.description.allIdentifiers

        if allEnabledRules.isDisjoint(with: allIdentifiers) {
            if !disabledRules.isDisjoint(with: allIdentifiers) {
                return Issue.ruleDisabledInDisabledRules(ruleID: ruleType.identifier)
            }
            if !disabledInParentRules.isDisjoint(with: allIdentifiers) {
                return Issue.ruleDisabledInParentConfiguration(ruleID: ruleType.identifier)
            }

            if ruleType is any OptInRule.Type {
                if enabledInParentRules.union(optInRules).isDisjoint(with: allIdentifiers) {
                    return Issue.ruleNotEnabledInOptInRules(ruleID: ruleType.identifier)
                }
            } else if case .only(let enabledInParentRules) = parentConfiguration?.rulesMode,
                      enabledInParentRules.isDisjoint(with: allIdentifiers) {
                return Issue.ruleNotEnabledInParentOnlyRules(ruleID: ruleType.identifier)
            }
        }

        return nil
    }

    private static func warnAboutMisplacedAnalyzerRules(optInRules: [String], ruleList: RuleList) {
        let analyzerRules = ruleList.list
            .filter { $0.value.self is any AnalyzerRule.Type }
            .map(\.key)
        Set(analyzerRules).intersection(optInRules)
            .sorted()
            .forEach {
                Issue.genericWarning(
                    """
                    '\($0)' should be listed in the 'analyzer_rules' configuration section \
                    for more clarity as it is only run by 'swiftlint analyze'.
                    """
                ).print()
            }
    }
}
