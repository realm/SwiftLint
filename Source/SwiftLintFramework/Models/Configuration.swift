//
//  Configuration.swift
//  SwiftLint
//
//  Created by JP Simard on 8/23/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct Configuration: Equatable {
    // Represents how a Configuration object can be configured with regards to rules.
    public enum RulesMode {
        case `default`(disabled: [String], optIn: [String])
        case whitelisted([String])
        case allEnabled
    }

    // MARK: Properties

    public static let fileName = ".swiftlint.yml"

    public let included: [String]                      // included
    public let excluded: [String]                      // excluded
    public let reporter: String                        // reporter (xcode, json, csv, checkstyle)
    public let warningThreshold: Int?                  // warning threshold
    public private(set) var rootPath: String?          // the root path to search for nested configurations
    public private(set) var configurationPath: String? // if successfully loaded from a path
    public let cachePath: String?

    // MARK: Rules Properties

    // All rules enabled in this configuration, derived from disabled, opt-in and whitelist rules
    public let rules: [Rule]

    internal let rulesMode: RulesMode

    // MARK: Initializers

    public init?(rulesMode: RulesMode = .default(disabled: [], optIn: []),
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

        let configuredRules = configuredRules
            ?? (try? ruleList.configuredRules(with: [:]))
            ?? []

        let handleAliasWithRuleList: (String) -> String = { ruleList.identifier(for: $0) ?? $0 }

        let validRuleIdentifiers = configuredRules.map { type(of: $0).description.identifier }

        let rules: [Rule]
        switch rulesMode {
        case .allEnabled:
            rules = configuredRules
        case .whitelisted(let whitelistedRuleIdentifiers):
            let validWhitelistedRuleIdentifiers = validateRuleIdentifiers(
                ruleIdentifiers: whitelistedRuleIdentifiers.map(handleAliasWithRuleList),
                validRuleIdentifiers: validRuleIdentifiers)
            // Validate that rule identifiers aren't listed multiple times
            if containsDuplicateIdentifiers(validWhitelistedRuleIdentifiers) {
                return nil
            }
            rules = configuredRules.filter { rule in
                return validWhitelistedRuleIdentifiers.contains(type(of: rule).description.identifier)
            }
        case let .default(disabledRuleIdentifiers, optInRuleIdentifiers):
            let validDisabledRuleIdentifiers = validateRuleIdentifiers(
                ruleIdentifiers: disabledRuleIdentifiers.map(handleAliasWithRuleList),
                validRuleIdentifiers: validRuleIdentifiers)
            let validOptInRuleIdentifiers = validateRuleIdentifiers(
                ruleIdentifiers: optInRuleIdentifiers.map(handleAliasWithRuleList),
                validRuleIdentifiers: validRuleIdentifiers)
            // Same here
            if containsDuplicateIdentifiers(validDisabledRuleIdentifiers)
                || containsDuplicateIdentifiers(validOptInRuleIdentifiers) {

                return nil
            }
            rules = configuredRules.filter { rule in
                let id = type(of: rule).description.identifier
                if validDisabledRuleIdentifiers.contains(id) { return false }
                return validOptInRuleIdentifiers.contains(id) || !(rule is OptInRule)
            }
        }
        self.init(rulesMode: rulesMode,
                  included: included,
                  excluded: excluded,
                  warningThreshold: warningThreshold,
                  reporter: reporter,
                  rules: rules,
                  cachePath: cachePath)
    }

    internal init(rulesMode: RulesMode,
                  included: [String],
                  excluded: [String],
                  warningThreshold: Int?,
                  reporter: String,
                  rules: [Rule],
                  cachePath: String?,
                  rootPath: String? = nil) {

        self.rulesMode = rulesMode
        self.included = included
        self.excluded = excluded
        self.reporter = reporter
        self.cachePath = cachePath
        self.rules = rules
        self.rootPath = rootPath

        // set the config threshold to the threshold provided in the config file
        self.warningThreshold = warningThreshold
    }

    private init(_ configuration: Configuration) {
        rulesMode = configuration.rulesMode
        included = configuration.included
        excluded = configuration.excluded
        warningThreshold = configuration.warningThreshold
        reporter = configuration.reporter
        rules = configuration.rules
        cachePath = configuration.cachePath
        rootPath = configuration.rootPath
    }

    public init(path: String = Configuration.fileName, rootPath: String? = nil,
                optional: Bool = true, quiet: Bool = false, enableAllRules: Bool = false, cachePath: String? = nil) {
        let fullPath: String
        if let rootPath = rootPath, rootPath.isDirectory() {
            fullPath = path.bridge().absolutePathRepresentation(rootDirectory: rootPath)
        } else {
            fullPath = path.bridge().absolutePathRepresentation()
        }

        if let cachedConfig = Configuration.getCached(atPath: fullPath) {
            self.init(cachedConfig)
            configurationPath = fullPath
            return
        }

        let fail = { (msg: String) in
            queuedPrintError("\(fullPath):\(msg)")
            queuedFatalError("Could not read configuration file at path '\(fullPath)'")
        }
        let rulesMode: RulesMode = enableAllRules ? .allEnabled : .default(disabled: [], optIn: [])
        if path.isEmpty || !FileManager.default.fileExists(atPath: fullPath) {
            if !optional { fail("File not found.") }
            self.init(rulesMode: rulesMode, cachePath: cachePath)!
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
        self.init(rulesMode: rulesMode, cachePath: cachePath)!
        setCached(atPath: fullPath)
    }

    // MARK: Equatable

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return (lhs.excluded == rhs.excluded) &&
            (lhs.included == rhs.included) &&
            (lhs.reporter == rhs.reporter) &&
            (lhs.configurationPath == rhs.configurationPath) &&
            (lhs.rootPath == lhs.rootPath) &&
            (lhs.rules == rhs.rules)
    }
}

// MARK: Identifier Validation

private func validateRuleIdentifiers(ruleIdentifiers: [String], validRuleIdentifiers: [String]) -> [String] {
    // Validate that all rule identifiers map to a defined rule
    let invalidRuleIdentifiers = ruleIdentifiers.filter { !validRuleIdentifiers.contains($0) }
    if !invalidRuleIdentifiers.isEmpty {
        for invalidRuleIdentifier in invalidRuleIdentifiers {
            queuedPrintError("configuration error: '\(invalidRuleIdentifier)' is not a valid rule identifier")
        }
        let listOfValidRuleIdentifiers = validRuleIdentifiers.sorted().joined(separator: "\n")
        queuedPrintError("Valid rule identifiers:\n\(listOfValidRuleIdentifiers)")
    }

    return ruleIdentifiers.filter(validRuleIdentifiers.contains)
}

private func containsDuplicateIdentifiers(_ identifiers: [String]) -> Bool {
    // Validate that rule identifiers aren't listed multiple times

    guard Set(identifiers).count != identifiers.count else {
        return false
    }

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

private extension String {
    func isDirectory() -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory: &isDir) {
            #if os(Linux)
                return isDir
            #else
                return isDir.boolValue
            #endif
        }

        return false
    }
}
