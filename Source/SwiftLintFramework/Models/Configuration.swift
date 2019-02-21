import Foundation
import SourceKittenFramework

public struct Configuration: Hashable {
    // Represents how a Configuration object can be configured with regards to rules.
    public enum RulesMode {
        case `default`(disabled: [String], optIn: [String])
        case whitelisted([String])
        case allEnabled
    }

    // MARK: Properties

    public static let fileName = ".swiftlint.yml"

    public let indentation: IndentationStyle           // style to use when indenting
    public let included: [String]                      // included
    public let excluded: [String]                      // excluded
    public let reporter: String                        // reporter (xcode, json, csv, checkstyle)
    public let warningThreshold: Int?                  // warning threshold
    public private(set) var rootPath: String?          // the root path to search for nested configurations
    public private(set) var configurationPath: String? // if successfully loaded from a path
    public let cachePath: String?

    public func hash(into hasher: inout Hasher) {
        if let configurationPath = configurationPath {
            hasher.combine(configurationPath)
        } else if let rootPath = rootPath {
            hasher.combine(rootPath)
        } else if let cachePath = cachePath {
            hasher.combine(cachePath)
        } else {
            hasher.combine(included)
            hasher.combine(excluded)
            hasher.combine(reporter)
        }
    }

    internal var computedCacheDescription: String?

    internal var customRuleIdentifiers: [String] {
        let customRule = rules.first(where: { $0 is CustomRules }) as? CustomRules
        return customRule?.configuration.customRuleConfigurations.map { $0.identifier } ?? []
    }

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
                 cachePath: String? = nil,
                 indentation: IndentationStyle = .default,
                 customRulesIdentifiers: [String] = []) {
        if let pinnedVersion = swiftlintVersion, pinnedVersion != Version.current.value {
            queuedPrintError("Currently running SwiftLint \(Version.current.value) but " +
                "configuration specified version \(pinnedVersion).")
            exit(2)
        }

        let configuredRules = configuredRules
            ?? (try? ruleList.configuredRules(with: [:]))
            ?? []

        let handleAliasWithRuleList: (String) -> String = { ruleList.identifier(for: $0) ?? $0 }

        guard let rules = enabledRules(from: configuredRules,
                                       with: rulesMode,
                                       aliasResolver: handleAliasWithRuleList,
                                       customRulesIdentifiers: customRulesIdentifiers) else {
            return nil
        }

        self.init(rulesMode: rulesMode,
                  included: included,
                  excluded: excluded,
                  warningThreshold: warningThreshold,
                  reporter: reporter,
                  rules: rules,
                  cachePath: cachePath,
                  indentation: indentation)
    }

    internal init(rulesMode: RulesMode,
                  included: [String],
                  excluded: [String],
                  warningThreshold: Int?,
                  reporter: String,
                  rules: [Rule],
                  cachePath: String?,
                  rootPath: String? = nil,
                  indentation: IndentationStyle) {
        self.rulesMode = rulesMode
        self.included = included
        self.excluded = excluded
        self.reporter = reporter
        self.cachePath = cachePath
        self.rules = rules
        self.rootPath = rootPath
        self.indentation = indentation

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
        indentation = configuration.indentation
    }

    public init(path: String = Configuration.fileName, rootPath: String? = nil,
                optional: Bool = true, quiet: Bool = false, enableAllRules: Bool = false,
                cachePath: String? = nil, customRulesIdentifiers: [String] = []) {
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
            self.init(rulesMode: rulesMode, cachePath: cachePath, customRulesIdentifiers: customRulesIdentifiers)!
            self.rootPath = rootPath
            return
        }
        do {
            let yamlContents = try String(contentsOfFile: fullPath, encoding: .utf8)
            let dict = try YamlParser.parse(yamlContents)
            if !quiet {
                queuedPrintError("Loading configuration from '\(path)'")
            }
            self.init(dict: dict, enableAllRules: enableAllRules,
                      cachePath: cachePath, customRulesIdentifiers: customRulesIdentifiers)!
            configurationPath = fullPath
            self.rootPath = rootPath
            setCached(atPath: fullPath)
            return
        } catch YamlParserError.yamlParsing(let message) {
            fail(message)
        } catch {
            fail("\(error)")
        }
        self.init(rulesMode: rulesMode, cachePath: cachePath, customRulesIdentifiers: customRulesIdentifiers)!
        setCached(atPath: fullPath)
    }

    // MARK: Equatable

    public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
        return (lhs.warningThreshold == rhs.warningThreshold) &&
            (lhs.reporter == rhs.reporter) &&
            (lhs.rootPath == rhs.rootPath) &&
            (lhs.configurationPath == rhs.configurationPath) &&
            (lhs.cachePath == rhs.cachePath) &&
            (lhs.included == rhs.included) &&
            (lhs.excluded == rhs.excluded) &&
            (lhs.rules == rhs.rules) &&
            (lhs.indentation == rhs.indentation)
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

    let duplicateRules = identifiers.reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        .filter { $0.1 > 1 }
    queuedPrintError(duplicateRules.map { rule in
        "configuration error: '\(rule.0)' is listed \(rule.1) times"
    }.joined(separator: "\n"))
    return true
}

private func enabledRules(from configuredRules: [Rule],
                          with mode: Configuration.RulesMode,
                          aliasResolver: (String) -> String,
                          customRulesIdentifiers: [String]) -> [Rule]? {
    let regularRuleIdentifiers = configuredRules.map { type(of: $0).description.identifier }
    let configurationCustomRulesIdentifiers = (configuredRules.first(where: { $0 is CustomRules }) as? CustomRules)?
        .configuration.customRuleConfigurations.map { $0.identifier } ?? []
    let validRuleIdentifiers = regularRuleIdentifiers + configurationCustomRulesIdentifiers + customRulesIdentifiers

    switch mode {
    case .allEnabled:
        return configuredRules
    case .whitelisted(let whitelistedRuleIdentifiers):
        let validWhitelistedRuleIdentifiers = validateRuleIdentifiers(
            ruleIdentifiers: whitelistedRuleIdentifiers.map(aliasResolver),
            validRuleIdentifiers: validRuleIdentifiers)
        // Validate that rule identifiers aren't listed multiple times
        if containsDuplicateIdentifiers(validWhitelistedRuleIdentifiers) {
            return nil
        }
        return configuredRules.filter { rule in
            return validWhitelistedRuleIdentifiers.contains(type(of: rule).description.identifier)
        }
    case let .default(disabledRuleIdentifiers, optInRuleIdentifiers):
        let validDisabledRuleIdentifiers = validateRuleIdentifiers(
            ruleIdentifiers: disabledRuleIdentifiers.map(aliasResolver),
            validRuleIdentifiers: validRuleIdentifiers)
        let validOptInRuleIdentifiers = validateRuleIdentifiers(
            ruleIdentifiers: optInRuleIdentifiers.map(aliasResolver),
            validRuleIdentifiers: validRuleIdentifiers)
        // Same here
        if containsDuplicateIdentifiers(validDisabledRuleIdentifiers)
            || containsDuplicateIdentifiers(validOptInRuleIdentifiers) {
            return nil
        }
        return configuredRules.filter { rule in
            let id = type(of: rule).description.identifier
            if validDisabledRuleIdentifiers.contains(id) { return false }
            return validOptInRuleIdentifiers.contains(id) || !(rule is OptInRule)
        }
    }
}

private extension String {
    func isDirectory() -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: self, isDirectory: &isDir) {
            return isDir.boolValue
        }

        return false
    }
}
