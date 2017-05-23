//
//  Configuration.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum ConfigurationKey: String {
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

public struct Configuration: Equatable {
    public static let fileName = ".swiftlint.yml"
    public let included: [String]             // included
    public let excluded: [String]             // excluded
    public let reporter: String               // reporter (xcode, json, csv, checkstyle)
    public var warningThreshold: Int?         // warning threshold
    public let rules: [Rule]
    public var rootPath: String?              // the root path to search for nested configurations
    public var configurationPath: String?     // if successfully loaded from a path
    public let cachePath: String?

    public init?(disabledRules: [String] = [],
                 optInRules: [String] = [],
                 enableAllRules: Bool = false,
                 whitelistRules: [String] = [],
                 included: [String] = [],
                 excluded: [String] = [],
                 warningThreshold: Int? = nil,
                 reporter: String = XcodeReporter.identifier,
                 ruleList: RuleList = masterRuleList,
                 configuredRules: [Rule]? = nil,
                 swiftlintVersion: String? = nil,
                 cachePath: String? = nil) {

        if let pinnedVersion = swiftlintVersion, pinnedVersion != Version.current.value {
            queuedPrintError("Currently running SwiftLint \(Version.current.value) but " +
                "configuration specified version \(pinnedVersion).")
        }

        self.included = included
        self.excluded = excluded
        self.reporter = reporter
        self.cachePath = cachePath

        let configuredRules = configuredRules
            ?? (try? ruleList.configuredRules(with: [:]))
            ?? []

        let handleAliasWithRuleList = { (alias: String) -> String in
            return ruleList.identifier(for: alias) ?? alias
        }

        let disabledRules = disabledRules.map(handleAliasWithRuleList)
        let optInRules = optInRules.map(handleAliasWithRuleList)
        let whitelistRules = whitelistRules.map(handleAliasWithRuleList)

        // Validate that all rule identifiers map to a defined rule
        let validRuleIdentifiers = validateRuleIdentifiers(configuredRules: configuredRules,
                                                           disabledRules: disabledRules)
        let validDisabledRules = disabledRules.filter(validRuleIdentifiers.contains)

        // Validate that rule identifiers aren't listed multiple times
        if containsDuplicateIdentifiers(validDisabledRules) {
            return nil
        }

        // set the config threshold to the threshold provided in the config file
        self.warningThreshold = warningThreshold

        // Precedence is enableAllRules > whitelistRules > everything else
        if enableAllRules {
            rules = configuredRules
        } else if !whitelistRules.isEmpty {
            if !disabledRules.isEmpty || !optInRules.isEmpty {
                queuedPrintError("'\(ConfigurationKey.disabledRules.rawValue)' or " +
                    "'\(ConfigurationKey.optInRules.rawValue)' cannot be used in combination " +
                    "with '\(ConfigurationKey.whitelistRules.rawValue)'")
                return nil
            }

            rules = configuredRules.filter { rule in
                return whitelistRules.contains(type(of: rule).description.identifier)
            }
        } else {
            rules = configuredRules.filter { rule in
                let id = type(of: rule).description.identifier
                if validDisabledRules.contains(id) { return false }
                return optInRules.contains(id) || !(rule is OptInRule)
            }
        }
    }

    public init?(dict: [String: Any], ruleList: RuleList = masterRuleList, enableAllRules: Bool = false,
                 cachePath: String? = nil) {
        // Use either new 'opt_in_rules' or deprecated 'enabled_rules' for now.
        let optInRules = defaultStringArray(
            dict[ConfigurationKey.optInRules.rawValue] ?? dict[ConfigurationKey.enabledRules.rawValue]
        )

        // Log an error when supplying invalid keys in the configuration dictionary
        let invalidKeys = Set(dict.keys).subtracting(validKeys(ruleList: ruleList))
        if !invalidKeys.isEmpty {
            queuedPrintError("Configuration contains invalid keys:\n\(invalidKeys)")
        }

        let disabledRules = defaultStringArray(dict[ConfigurationKey.disabledRules.rawValue])
        let whitelistRules = defaultStringArray(dict[ConfigurationKey.whitelistRules.rawValue])
        let included = defaultStringArray(dict[ConfigurationKey.included.rawValue])
        let excluded = defaultStringArray(dict[ConfigurationKey.excluded.rawValue])

        warnAboutDeprecations(configurationDictionary: dict, disabledRules: disabledRules, optInRules: optInRules,
                              whitelistRules: whitelistRules, ruleList: ruleList)

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
                  warningThreshold: dict[ConfigurationKey.warningThreshold.rawValue] as? Int,
                  reporter: dict[ConfigurationKey.reporter.rawValue] as? String ??
                    XcodeReporter.identifier,
                  ruleList: ruleList,
                  configuredRules: configuredRules,
                  swiftlintVersion: dict[ConfigurationKey.swiftlintVersion.rawValue] as? String,
                  cachePath: cachePath ?? dict[ConfigurationKey.cachePath.rawValue] as? String)
    }

    public init(path: String = Configuration.fileName, rootPath: String? = nil,
                optional: Bool = true, quiet: Bool = false, enableAllRules: Bool = false, cachePath: String? = nil) {
        let fullPath = path.bridge().absolutePathRepresentation()
        let fail = { (msg: String) in
            queuedPrintError("\(fullPath):\(msg)")
            fatalError("Could not read configuration file at path '\(fullPath)'")
        }
        if path.isEmpty || !FileManager.default.fileExists(atPath: fullPath) {
            if !optional { fail("File not found.") }
            self.init(enableAllRules: enableAllRules, cachePath: cachePath)!
            self.rootPath = rootPath
            return
        }
        do {
            let yamlContents = try String(contentsOfFile: fullPath, encoding: .utf8)
            let dict = try YamlParser.parse(yamlContents)
            if !quiet {
                queuedPrintError("Loading configuration from '\(path)'")
            }
            self.init(dict: dict, enableAllRules: enableAllRules, cachePath: cachePath)!
            configurationPath = fullPath
            self.rootPath = rootPath
            setCached(atPath: fullPath)
            return
        } catch YamlParserError.yamlParsing(let message) {
            fail(message)
        } catch {
            fail("\(error)")
        }
        self.init(enableAllRules: enableAllRules, cachePath: cachePath)!
        setCached(atPath: fullPath)
    }

    public init(commandLinePath: String, rootPath: String? = nil, quiet: Bool = false, enableAllRules: Bool = false,
                cachePath: String? = nil) {
        self.init(path: commandLinePath, rootPath: rootPath?.absolutePathStandardized(),
                  optional: !CommandLine.arguments.contains("--config"), quiet: quiet, enableAllRules: enableAllRules,
                  cachePath: cachePath)
    }

    public func lintablePaths(inPath path: String, fileManager: LintableFileManager = FileManager.default) -> [String] {
        // If path is a Swift file, skip filtering with excluded/included paths
        if path.bridge().isSwiftFile() && path.isFile {
            return [path]
        }
        let pathsForPath = included.isEmpty ? fileManager.filesToLint(inPath: path, rootDirectory: nil) : []
        let excludedPaths = excluded.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        let includedPaths = included.flatMap {
            fileManager.filesToLint(inPath: $0, rootDirectory: rootPath)
        }
        return (pathsForPath + includedPaths).filter({ !excludedPaths.contains($0) })
    }

    public func lintableFiles(inPath path: String) -> [File] {
        return lintablePaths(inPath: path).flatMap { File(path: $0) }
    }

    public func configuration(for file: File) -> Configuration {
        if let containingDir = file.path?.bridge().deletingLastPathComponent {
            return configuration(forPath: containingDir)
        }
        return self
    }
}

private func validateRuleIdentifiers(configuredRules: [Rule], disabledRules: [String]) -> [String] {
    // Validate that all rule identifiers map to a defined rule
    let validRuleIdentifiers = configuredRules.map { type(of: $0).description.identifier }

    let invalidRules = disabledRules.filter { !validRuleIdentifiers.contains($0) }
    if !invalidRules.isEmpty {
        for invalidRule in invalidRules {
            queuedPrintError("configuration error: '\(invalidRule)' is not a valid rule identifier")
        }
        let listOfValidRuleIdentifiers = validRuleIdentifiers.joined(separator: "\n")
        queuedPrintError("Valid rule identifiers:\n\(listOfValidRuleIdentifiers)")
    }

    return validRuleIdentifiers
}

private func containsDuplicateIdentifiers(_ identifiers: [String]) -> Bool {
    // Validate that rule identifiers aren't listed multiple times
    if Set(identifiers).count != identifiers.count {
        let duplicateRules = identifiers.reduce([String: Int]()) { accu, element in
            var accu = accu
            accu[element] = (accu[element] ?? 0) + 1
            return accu
        }.filter { $0.1 > 1 }
        queuedPrintError(duplicateRules.map { rule in
            "configuration error: '\(rule.0)' is listed \(rule.1) times"
        }.joined(separator: "\n"))
        return true
    }

    return false
}

private func defaultStringArray(_ object: Any?) -> [String] {
    return [String].array(of: object) ?? []
}

private func validKeys(ruleList: RuleList) -> [String] {
    return [
        ConfigurationKey.cachePath,
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

private func warnAboutDeprecations(configurationDictionary dict: [String: Any],
                                   disabledRules: [String] = [],
                                   optInRules: [String] = [],
                                   whitelistRules: [String] = [],
                                   ruleList: RuleList) {

    // Deprecation warning for "enabled_rules"
    if dict[ConfigurationKey.enabledRules.rawValue] != nil {
        queuedPrintError("'\(ConfigurationKey.enabledRules.rawValue)' has been renamed to " +
            "'\(ConfigurationKey.optInRules.rawValue)' and will be completely removed in a " +
            "future release.")
    }

    // Deprecation warning for "use_nested_configs"
    if dict[ConfigurationKey.useNestedConfigs.rawValue] != nil {
        queuedPrintError("Support for '\(ConfigurationKey.useNestedConfigs.rawValue)' has " +
            "been deprecated and its value is now ignored. Nested configuration files are " +
            "now always considered.")
    }

    // Deprecation warning for rules
    let deprecatedRulesIdentifiers = ruleList.list.flatMap { (identifier, rule) -> [(String, String)] in
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

// MARK: - Nested Configurations Extension

extension Configuration {
    fileprivate func configuration(forPath path: String) -> Configuration {
        let pathNSString = path.bridge()
        let configurationSearchPath = pathNSString.appendingPathComponent(Configuration.fileName)

        // If a configuration exists and it isn't us, load and merge the configurations
        if configurationSearchPath != configurationPath &&
            FileManager.default.fileExists(atPath: configurationSearchPath) {
            let fullPath = pathNSString.absolutePathRepresentation()
            let config = Configuration.getCached(atPath: fullPath) ??
                Configuration(path: configurationSearchPath, rootPath: rootPath, optional: false, quiet: true)
            return merge(with: config)
        }

        // If we are not at the root path, continue down the tree
        if path != rootPath && path != "/" {
            return configuration(forPath: pathNSString.deletingLastPathComponent)
        }

        // If nothing else, return self
        return self
    }

    // Currently merge simply overrides the current configuration with the new configuration.
    // This requires that all configuration files be fully specified. In the future this should be
    // improved to do a more intelligent merge allowing for partial nested configurations.
    internal func merge(with configuration: Configuration) -> Configuration {
        return configuration
    }
}

// Mark - == Implementation

public func == (lhs: Configuration, rhs: Configuration) -> Bool {
    return (lhs.excluded == rhs.excluded) &&
           (lhs.included == rhs.included) &&
           (lhs.reporter == rhs.reporter) &&
           (lhs.configurationPath == rhs.configurationPath) &&
           (lhs.rootPath == lhs.rootPath) &&
           (lhs.rules == rhs.rules)
}
