//
//  Configuration+Parsing.swift
//  SwiftLint
//
//  Created by JP Simard on 7/17/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

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
    }

    private static func validKeys(ruleList: RuleList) -> [String] {
        return [
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
            .whitelistRules
        ].map({ $0.rawValue }) + ruleList.allValidIdentifiers()
    }

    public init?(dict: [String: Any], ruleList: RuleList = masterRuleList, enableAllRules: Bool = false,
                 cachePath: String? = nil) {
        func defaultStringArray(_ object: Any?) -> [String] {
            return [String].array(of: object) ?? []
        }

        // Use either new 'opt_in_rules' or deprecated 'enabled_rules' for now.
        let optInRules = defaultStringArray(
            dict[Key.optInRules.rawValue] ?? dict[Key.enabledRules.rawValue]
        )

        // Log an error when supplying invalid keys in the configuration dictionary
        let invalidKeys = Set(dict.keys).subtracting(Configuration.validKeys(ruleList: ruleList))
        if !invalidKeys.isEmpty {
            queuedPrintError("Configuration contains invalid keys:\n\(invalidKeys)")
        }

        let disabledRules = defaultStringArray(dict[Key.disabledRules.rawValue])
        let whitelistRules = defaultStringArray(dict[Key.whitelistRules.rawValue])
        let included = defaultStringArray(dict[Key.included.rawValue])
        let excluded = defaultStringArray(dict[Key.excluded.rawValue])

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

        self.init(disabledRules: disabledRules,
                  optInRules: optInRules,
                  enableAllRules: enableAllRules,
                  whitelistRules: whitelistRules,
                  included: included,
                  excluded: excluded,
                  warningThreshold: dict[Key.warningThreshold.rawValue] as? Int,
                  reporter: dict[Key.reporter.rawValue] as? String ?? XcodeReporter.identifier,
                  ruleList: ruleList,
                  configuredRules: configuredRules,
                  swiftlintVersion: dict[Key.swiftlintVersion.rawValue] as? String,
                  cachePath: cachePath ?? dict[Key.cachePath.rawValue] as? String)
    }

    private init?(disabledRules: [String],
                  optInRules: [String],
                  enableAllRules: Bool,
                  whitelistRules: [String],
                  included: [String],
                  excluded: [String],
                  warningThreshold: Int?,
                  reporter: String = XcodeReporter.identifier,
                  ruleList: RuleList = masterRuleList,
                  configuredRules: [Rule]?,
                  swiftlintVersion: String?,
                  cachePath: String?) {

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
            rulesMode = .whitelisted(whitelistRules)
        } else {
            rulesMode = .default(disabled: disabledRules, optIn: optInRules)
        }

        self.init(rulesMode: rulesMode,
                  included: included,
                  excluded: excluded,
                  warningThreshold: warningThreshold,
                  reporter: reporter,
                  ruleList: ruleList,
                  configuredRules: configuredRules,
                  swiftlintVersion: swiftlintVersion,
                  cachePath: cachePath)
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
}
