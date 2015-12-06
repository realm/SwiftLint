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

public struct Configuration {
    public let disabledRules: [String] // disabled_rules
    public let included: [String]      // included
    public let excluded: [String]      // excluded
    public let reporter: String        // reporter (xcode, json, csv)
    public let rules: [Rule]

    public var reporterFromString: Reporter.Type {
        switch reporter {
        case XcodeReporter.identifier:
            return XcodeReporter.self
        case JSONReporter.identifier:
            return JSONReporter.self
        case CSVReporter.identifier:
            return CSVReporter.self
        default:
            fatalError("no reporter with identifier '\(reporter)' available.")
        }
    }

    public init?(disabledRules: [String] = [],
                 included: [String] = [],
                 excluded: [String] = [],
                 reporter: String = "xcode",
                 rules: [Rule] = Configuration.rulesFromYAML()) {
        self.included = included
        self.excluded = excluded
        self.reporter = reporter

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
        guard let yamlConfig = Yaml.load(yaml).value else {
            return nil
        }
        self.init(
            disabledRules: yamlConfig["disabled_rules"].arrayOfStrings ?? [],
            included: yamlConfig["included"].arrayOfStrings ?? [],
            excluded: yamlConfig["excluded"].arrayOfStrings ?? [],
            reporter: yamlConfig["reporter"].string ?? XcodeReporter.identifier,
            rules: Configuration.rulesFromYAML(yamlConfig)
        )
    }

    public init(path: String = ".swiftlint.yml", optional: Bool = true) {
        let fullPath = (path as NSString).absolutePathRepresentation()
        let failIfRequired = {
            if !optional { fatalError("Could not read configuration file at path '\(fullPath)'") }
        }
        if path.isEmpty || !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
            failIfRequired()
            self.init()!
            return
        }
        do {
            let yamlContents = try NSString(contentsOfFile: fullPath,
                encoding: NSUTF8StringEncoding) as String
            if let _ = Configuration(yaml: yamlContents) {
                queuedPrintError("Loading configuration from '\(path)'")
                self.init(yaml: yamlContents)!
                return
            }
        } catch {
            failIfRequired()
        }
        self.init()!
    }

    public static func rulesFromYAML(yaml: Yaml? = nil) -> [Rule] {
        return [
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

    public func lintableFilesForPath(path: String) -> [File] {
        let pathsForPath = included.isEmpty ? fileManager.filesToLintAtPath(path) : []
        let excludedPaths = excluded.flatMap(fileManager.filesToLintAtPath)
        let includedPaths = included.flatMap(fileManager.filesToLintAtPath)
        let allPaths = pathsForPath.filter(excludedPaths.contains) + includedPaths
        return allPaths.flatMap { File(path: $0) }
    }
}
