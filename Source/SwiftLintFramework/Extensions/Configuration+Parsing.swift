extension Configuration {
    private enum Key: String {
        case cachePath = "cache_path"
        case disabledRules = "disabled_rules"
        case enabledRules = "enabled_rules" // deprecated in favor of optInRules
        case excluded = "excluded"
        case included = "included"
        case optInRules = "opt_in_rules"
        case reporter = "reporter"
        case swiftlintVersion = "swiftlint_version"
        case useNestedConfigs = "use_nested_configs" // deprecated
        case warningThreshold = "warning_threshold"
        case whitelistRules = "whitelist_rules"
        case indentation = "indentation"
        case analyzerRules = "analyzer_rules"
        case allowZeroLintableFiles  = "allow_zero_lintable_files"
    }

    private static let validGlobalKeys: Set<String> = {
        return Set([
            Key.cachePath,
            .disabledRules,
            .enabledRules,
            .excluded,
            .included,
            .optInRules,
            .reporter,
            .swiftlintVersion,
            .useNestedConfigs,
            .warningThreshold,
            .whitelistRules,
            .indentation,
            .analyzerRules,
            .allowZeroLintableFiles
        ].map({ $0.rawValue }))
    }()

    private static func validKeys(ruleList: RuleList) -> Set<String> {
        var keys = validGlobalKeys
        keys.formUnion(ruleList.allValidIdentifiers())
        return keys
    }

    private static func getIndentationLogIfInvalid(from dict: [String: Any]) -> IndentationStyle {
        if let rawIndentation = dict[Key.indentation.rawValue] {
            if let indentationStyle = Configuration.IndentationStyle(rawIndentation) {
                return indentationStyle
            }

            queuedPrintError("Invalid configuration for '\(Key.indentation)'. Falling back to default.")
            return .default
        }

        return .default
    }

    /// Creates a Configuration value based on the specified parameters.
    ///
    /// - parameter dict:                   The untyped dictionary to serve as the input for this typed configuration.
    ///                                     Typically generated from a YAML-formatted file.
    /// - parameter ruleList:               The list of rules to be available to this configuration.
    /// - parameter enableAllRules:         Whether all rules from `ruleList` should be enabled, regardless of the
    ///                                     settings in `dict`.
    /// - parameter cachePath:              The location of the persisted cache on disk.
    /// - parameter customRulesIdentifiers: All custom rule identifiers defined in the configuration.
    public init?(dict: [String: Any], ruleList: RuleList = masterRuleList, enableAllRules: Bool = false,
                 cachePath: String? = nil, customRulesIdentifiers: [String] = []) {
        // Use either new 'opt_in_rules' or deprecated 'enabled_rules' for now.
        let optInRules = defaultStringArray(dict[Key.optInRules.rawValue] ?? dict[Key.enabledRules.rawValue])

        Configuration.warnAboutInvalidKeys(configurationDictionary: dict, ruleList: ruleList)

        let disabledRules = defaultStringArray(dict[Key.disabledRules.rawValue])
        let whitelistRules = defaultStringArray(dict[Key.whitelistRules.rawValue])
        let analyzerRules = defaultStringArray(dict[Key.analyzerRules.rawValue])
        let included = defaultStringArray(dict[Key.included.rawValue])
        let excluded = defaultStringArray(dict[Key.excluded.rawValue])
        let indentation = Configuration.getIndentationLogIfInvalid(from: dict)
        let allowZeroLintableFiles = dict[Key.allowZeroLintableFiles.rawValue] as? Bool ?? false

        Configuration.warnAboutDeprecations(configurationDictionary: dict, disabledRules: disabledRules,
                                            optInRules: optInRules, whitelistRules: whitelistRules, ruleList: ruleList)

        let configuredRules: [Rule]
        do {
            configuredRules = try ruleList.configuredRules(with: dict)
        } catch RuleListError.duplicatedConfigurations(let ruleType) {
            let aliases = ruleType.description.deprecatedAliases.map { "'\($0)'" }.joined(separator: ", ")
            let identifier = ruleType.description.identifier
            queuedPrintError("Multiple configurations found for '\(identifier)'. Check for any aliases: \(aliases).")
            return nil
        } catch {
            return nil
        }

        let swiftlintVersion = dict[Key.swiftlintVersion.rawValue].map { ($0 as? String) ?? String(describing: $0) }
        self.init(disabledRules: disabledRules,
                  optInRules: optInRules,
                  enableAllRules: enableAllRules,
                  whitelistRules: whitelistRules,
                  analyzerRules: analyzerRules,
                  included: included,
                  excluded: excluded,
                  warningThreshold: dict[Key.warningThreshold.rawValue] as? Int,
                  reporter: dict[Key.reporter.rawValue] as? String ?? XcodeReporter.identifier,
                  ruleList: ruleList,
                  configuredRules: configuredRules,
                  swiftlintVersion: swiftlintVersion,
                  cachePath: cachePath ?? dict[Key.cachePath.rawValue] as? String,
                  indentation: indentation,
                  customRulesIdentifiers: customRulesIdentifiers,
                  allowZeroLintableFiles: allowZeroLintableFiles,
                  dict: dict)
    }

    private init?(disabledRules: [String],
                  optInRules: [String],
                  enableAllRules: Bool,
                  whitelistRules: [String],
                  analyzerRules: [String],
                  included: [String],
                  excluded: [String],
                  warningThreshold: Int?,
                  reporter: String = XcodeReporter.identifier,
                  ruleList: RuleList = masterRuleList,
                  configuredRules: [Rule]?,
                  swiftlintVersion: String?,
                  cachePath: String?,
                  indentation: IndentationStyle,
                  customRulesIdentifiers: [String],
                  allowZeroLintableFiles: Bool,
                  dict: [String: Any]) {
        let rulesMode: RulesMode
        if enableAllRules {
            rulesMode = .allEnabled
        } else if !whitelistRules.isEmpty {
            if !disabledRules.isEmpty || !optInRules.isEmpty {
                queuedPrintError("'\(Key.disabledRules.rawValue)' or " +
                    "'\(Key.optInRules.rawValue)' cannot be used in combination " +
                    "with '\(Key.whitelistRules.rawValue)'")
                return nil
            }
            rulesMode = .whitelisted(whitelistRules + analyzerRules)
        } else {
            rulesMode = .default(disabled: disabledRules, optIn: optInRules + analyzerRules)
        }

        Configuration.validateConfiguredRulesAreEnabled(configurationDictionary: dict, ruleList: ruleList,
                                                        rulesMode: rulesMode)

        self.init(rulesMode: rulesMode,
                  included: included,
                  excluded: excluded,
                  warningThreshold: warningThreshold,
                  reporter: reporter,
                  ruleList: ruleList,
                  configuredRules: configuredRules,
                  swiftlintVersion: swiftlintVersion,
                  cachePath: cachePath,
                  indentation: indentation,
                  customRulesIdentifiers: customRulesIdentifiers,
                  allowZeroLintableFiles: allowZeroLintableFiles)
    }

    private static func warnAboutDeprecations(configurationDictionary dict: [String: Any],
                                              disabledRules: [String] = [],
                                              optInRules: [String] = [],
                                              whitelistRules: [String] = [],
                                              ruleList: RuleList) {
        // Deprecation warning for "enabled_rules"
        if dict[Key.enabledRules.rawValue] != nil {
            queuedPrintError("'\(Key.enabledRules.rawValue)' has been renamed to " +
                "'\(Key.optInRules.rawValue)' and will be completely removed in a " +
                "future release.")
        }

        // Deprecation warning for "use_nested_configs"
        if dict[Key.useNestedConfigs.rawValue] != nil {
            queuedPrintError("Support for '\(Key.useNestedConfigs.rawValue)' has " +
                "been deprecated and its value is now ignored. Nested configuration files are " +
                "now always considered.")
        }

        // Deprecation warning for rules
        let deprecatedRulesIdentifiers = ruleList.list.flatMap { identifier, rule -> [(String, String)] in
            return rule.description.deprecatedAliases.map { ($0, identifier) }
        }

        let userProvidedRuleIDs = Set(disabledRules + optInRules + whitelistRules)
        let deprecatedUsages = deprecatedRulesIdentifiers.filter { deprecatedIdentifier, _ in
            return dict[deprecatedIdentifier] != nil || userProvidedRuleIDs.contains(deprecatedIdentifier)
        }

        for (deprecatedIdentifier, identifier) in deprecatedUsages {
            queuedPrintError("'\(deprecatedIdentifier)' rule has been renamed to '\(identifier)' and will be " +
                "completely removed in a future release.")
        }
    }

    private static func warnAboutInvalidKeys(configurationDictionary dict: [String: Any], ruleList: RuleList) {
        // Log an error when supplying invalid keys in the configuration dictionary
        let invalidKeys = Set(dict.keys).subtracting(self.validKeys(ruleList: ruleList))
        if !invalidKeys.isEmpty {
            queuedPrintError("Configuration contains invalid keys:\n\(invalidKeys)")
        }
    }

    private static func validateConfiguredRulesAreEnabled(configurationDictionary dict: [String: Any],
                                                          ruleList: RuleList,
                                                          rulesMode: RulesMode) {
        for key in dict.keys where !validGlobalKeys.contains(key) {
            guard let identifier = ruleList.identifier(for: key),
                let rule = ruleList.list[identifier] else {
                    continue
            }

            let message = "Found a configuration for '\(identifier)' rule"

            switch rulesMode {
            case .allEnabled:
                return
            case .whitelisted(let whitelist):
                if Set(whitelist).isDisjoint(with: rule.description.allIdentifiers) {
                    queuedPrintError("\(message), but it is not present on " +
                        "'\(Key.whitelistRules.rawValue)'.")
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
}

private func defaultStringArray(_ object: Any?) -> [String] {
    return [String].array(of: object) ?? []
}
