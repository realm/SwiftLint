//
//  Configuration.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-08-23.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import Yaml

private let fileManager = NSFileManager.defaultManager()

extension Yaml {
    var arrayOfStrings: [Swift.String]? {
        return array?.flatMap { $0.string } ?? string.map { [$0] }
    }
    var arrayOfInts: [Swift.Int]? {
        return array?.flatMap { $0.int } ?? int.map { [$0] }
    }
}

public struct Configuration: Equatable {
    public let disabledRules: [String] // disabled_rules
    public let included: [String]      // included
    public let excluded: [String]      // excluded
    public let reporter: String        // reporter (xcode, json, csv, checkstyle)
    public let rules: [Rule]
    public let useNestedConfigs: Bool  // process nested configs, will default to false
    public var rootPath: String?       // the root path of the lint to search for nested configs
    private var configPath: String?    // if successfully load from a path

    public var reporterFromString: Reporter.Type {
        switch reporter {
        case XcodeReporter.identifier:
            return XcodeReporter.self
        case JSONReporter.identifier:
            return JSONReporter.self
        case CSVReporter.identifier:
            return CSVReporter.self
        case CheckstyleReporter.identifier:
            return CheckstyleReporter.self
        default:
            fatalError("no reporter with identifier '\(reporter)' available.")
        }
    }

    public init?(disabledRules: [String] = [],
                 included: [String] = [],
                 excluded: [String] = [],
                 reporter: String = "xcode",
                 rules: [Rule] = Configuration.rulesFromYAML(),
                 useNestedConfigs: Bool = false) {
        self.included = included
        self.excluded = excluded
        self.reporter = reporter
        self.useNestedConfigs = useNestedConfigs

        // Validate that all rule identifiers map to a defined rule

        let validRuleIdentifiers = Configuration.rulesFromYAML().map {
            $0.dynamicType.description.identifier
        }

        let validDisabledRules = disabledRules.filter({ validRuleIdentifiers.contains($0)})
        let invalidRules = disabledRules.filter({ !validRuleIdentifiers.contains($0) })
        if !invalidRules.isEmpty {
            for invalidRule in invalidRules {
                queuedPrintError("config error: '\(invalidRule)' is not a valid rule identifier")
            }
            let listOfValidRuleIdentifiers = validRuleIdentifiers.joinWithSeparator("\n")
            queuedPrintError("Valid rule identifiers:\n\(listOfValidRuleIdentifiers)")
        }

        // Validate that rule identifiers aren't listed multiple times

        let ruleSet = Set(validDisabledRules)
        if ruleSet.count != validDisabledRules.count {
            let duplicateRules = validDisabledRules.reduce([String: Int]()) { (var accu, element) in
                accu[element] = accu[element]?.successor() ?? 1
                return accu
            }.filter { $0.1 > 1 }
            queuedPrintError(duplicateRules.map { rule in
                "config error: '\(rule.0)' is listed \(rule.1) times"
            }.joinWithSeparator("\n"))
            return nil
        }
        self.disabledRules = validDisabledRules

        self.rules = rules.filter {
            !validDisabledRules.contains($0.dynamicType.description.identifier)
        }
    }

    public init?(yaml: String) {
        guard let yamlConfig = Configuration.loadYaml(yaml) else {
            return nil
        }
        self.init(yamlConfig: yamlConfig)
    }

    private init?(yamlConfig: Yaml) {
        self.init(
            disabledRules: yamlConfig["disabled_rules"].arrayOfStrings ?? [],
            included: yamlConfig["included"].arrayOfStrings ?? [],
            excluded: yamlConfig["excluded"].arrayOfStrings ?? [],
            reporter: yamlConfig["reporter"].string ?? XcodeReporter.identifier,
            rules: Configuration.rulesFromYAML(yamlConfig),
            useNestedConfigs: yamlConfig["use_nested_configs"].bool ?? false
        )
    }

    private static func loadYaml(yaml: String) -> Yaml? {
        let yamlResult = Yaml.load(yaml)
        if let yamlConfig = yamlResult.value {
            return yamlConfig
        }
        if let error = yamlResult.error {
            queuedPrint(error)
        }
        return nil
    }

    public init(path: String = ".swiftlint.yml", optional: Bool = true, silent: Bool = false) {
        let fullPath = (path as NSString).absolutePathRepresentation()
        let fail = { fatalError("Could not read configuration file at path '\(fullPath)'") }
        if path.isEmpty || !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
            if !optional { fail() }
            self.init()!
            return
        }
        do {
            let yamlContents = try NSString(contentsOfFile: fullPath,
                encoding: NSUTF8StringEncoding) as String
            if let yamlConfig = Configuration.loadYaml(yamlContents) {
                if !silent {
                    queuedPrintError("Loading configuration from '\(path)'")
                }
                self.init(yamlConfig: yamlConfig)!
                configPath = fullPath
                return
            } else {
                fail()
            }
        } catch {
            fail()
        }
        self.init()!
    }

    public static func rulesFromYAML(yaml: Yaml? = nil) -> [Rule] {
        return [
            ConditionalBindingCascadeRule(),
            ClosingBraceRule(),
            ColonRule(),
            CommaRule(),
            ControlStatementRule(),
            ForceCastRule(),
            ForceTryRule(),
            LeadingWhitespaceRule(),
            LegacyConstructorRule(),
            NestingRule(),
            OpeningBraceRule(),
            OperatorFunctionWhitespaceRule(),
            ReturnArrowWhitespaceRule(),
            StatementPositionRule(),
            TodoRule(),
            TrailingNewlineRule(),
            TrailingSemicolonRule(),
            TrailingWhitespaceRule(),
            TypeNameRule(),
            ValidDocsRule(),
            VariableNameRule(),
        ] + parameterRulesFromYAML(yaml)
    }

    private static func parameterRulesFromYAML(yaml: Yaml? = nil) -> [Rule] {
        let intParams: (Rule.Type) -> [RuleParameter<Int>]? = {
            (yaml?[.String($0.description.identifier)].arrayOfInts).map(ruleParametersFromArray)
        }
        // swiftlint:disable line_length
        return [
            intParams(FileLengthRule).map(FileLengthRule.init) ?? FileLengthRule(),
            intParams(FunctionBodyLengthRule).map(FunctionBodyLengthRule.init) ?? FunctionBodyLengthRule(),
            intParams(LineLengthRule).map(LineLengthRule.init) ?? LineLengthRule(),
            intParams(TypeBodyLengthRule).map(TypeBodyLengthRule.init) ?? TypeBodyLengthRule(),
            intParams(VariableNameMaxLengthRule).map(VariableNameMaxLengthRule.init) ?? VariableNameMaxLengthRule(),
            intParams(VariableNameMinLengthRule).map(VariableNameMinLengthRule.init) ?? VariableNameMinLengthRule(),
        ]
        // swiftlint:enable line_length
    }

    private static func ruleParametersFromArray<T>(array: [T]) -> [RuleParameter<T>] {
        return zip([.Warning, .Error], array).map(RuleParameter.init)
    }

    public func lintablePathsForPath(path: String,
                                     fileManager: NSFileManager = fileManager) -> [String] {
        let pathsForPath = included.isEmpty ? fileManager.filesToLintAtPath(path) : []
        let excludedPaths = excluded.flatMap(fileManager.filesToLintAtPath)
        let includedPaths = included.flatMap(fileManager.filesToLintAtPath)
        return (pathsForPath + includedPaths).filter({ !excludedPaths.contains($0) })
    }

    public func lintableFilesForPath(path: String) -> [File] {
        let allPaths = self.lintablePathsForPath(path)
        return allPaths.flatMap { File(path: $0) }
    }

    public func configForFile(file: File) -> Configuration {
        if useNestedConfigs,
            let containingDir = (file.path as NSString?)?.stringByDeletingLastPathComponent {
            return configForPath(containingDir)
        }
        return self
    }
}

// MARK: - Nested Configurations Extension

public extension Configuration {
    func configForPath(path: String) -> Configuration {
        let path = path as NSString
        let configSearchPath = path.stringByAppendingPathComponent(".swiftlint.yml")

        // If a config exists and it isn't us, load and merge the configs
        if configSearchPath != configPath &&
            NSFileManager.defaultManager().fileExistsAtPath(configSearchPath) {
            return merge(Configuration(path: configSearchPath, optional: false, silent: true))
        }

        // If we are not at the root path, continue down the tree
        if path != rootPath {
            return configForPath(path.stringByDeletingLastPathComponent)
        }

        // If nothing else, return self
        return self
    }

    // Currently merge simply overrides the current configuration with the new configuration.
    // This requires that all config files be fully specified. In the future this will be changed
    // to do a more intelligent merge allowing for partial nested configs.
    func merge(config: Configuration) -> Configuration {
        return config
    }
}

// Mark - == Implementation

public func == (lhs: Configuration, rhs: Configuration) -> Bool {
    return (lhs.disabledRules == rhs.disabledRules) &&
           (lhs.excluded == rhs.excluded) &&
           (lhs.included == rhs.included) &&
           (lhs.reporter == rhs.reporter) &&
           (lhs.useNestedConfigs == rhs.useNestedConfigs) &&
           (lhs.configPath == rhs.configPath) &&
           (lhs.rootPath == lhs.rootPath) &&
           (lhs.rules == rhs.rules)
}
