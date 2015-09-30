//
//  Configuration.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-08-23.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Yaml

extension Yaml {
    var arrayOfStrings: [Swift.String]? {
        return array?.flatMap { $0.string }
    }
    var arrayOfInts: [Swift.Int]? {
        return array?.flatMap { $0.int }
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
                 rules: [Rule] = allRules) {
        self.disabledRules = disabledRules
        self.included = included
        self.excluded = excluded
        self.reporter = reporter

        // Validate that all rule identifiers map to a defined rule

        let validRuleIdentifiers = allRules.map { $0.identifier }

        let ruleSet = Set(disabledRules)
        let invalidRules = ruleSet.filter({ !validRuleIdentifiers.contains($0) })
        if invalidRules.count > 0 {
            for invalidRule in invalidRules {
                fputs("config error: '\(invalidRule)' is not a valid rule identifier\n", stderr)
                let listOfValidRuleIdentifiers = validRuleIdentifiers.joinWithSeparator("\n")
                fputs("Valid rule identifiers:\n\(listOfValidRuleIdentifiers)\n", stderr)
            }
            return nil
        }

        // Validate that rule identifiers aren't listed multiple times

        if ruleSet.count != disabledRules.count {
            let duplicateRules = disabledRules.reduce([String: Int]()) { (var accu, element) in
                accu[element] = accu[element]?.successor() ?? 1
                return accu
            }.filter {
                $0.1 > 1
            }
            for duplicateRule in duplicateRules {
                fputs("config error: '\(duplicateRule.0)' is listed \(duplicateRule.1) times\n",
                    stderr)
            }
            return nil
        }

        self.rules = rules.filter { !disabledRules.contains($0.identifier) }
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
        if path.isEmpty {
            failIfRequired()
            self.init()!
        } else {
            if !NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
                failIfRequired()
                self.init()!
                return
            }
            do {
                let yamlContents = try NSString(contentsOfFile: fullPath,
                    encoding: NSUTF8StringEncoding) as String
                if let _ = Configuration(yaml: yamlContents) {
                    print("Loading configuration from '\(path)'")
                    self.init(yaml: yamlContents)!
                } else {
                    self.init()!
                }
            } catch {
                failIfRequired()
                self.init()!
            }
        }
    }

    public static func rulesFromYAML(yaml: Yaml?) -> [Rule] {
        var rules = [Rule]()
        if let params = yaml?[.String(LineLengthRule().identifier)].arrayOfInts {
            rules.append(LineLengthRule(parameters: ruleParametersFromArray(params)))
        } else {
            rules.append(LineLengthRule())
        }
        rules.append(LeadingWhitespaceRule())
        rules.append(TrailingWhitespaceRule())
        rules.append(ReturnArrowWhitespaceRule())
        rules.append(TrailingNewlineRule())
        rules.append(OperatorFunctionWhitespaceRule())
        rules.append(ForceCastRule())
        if let params = yaml?[.String(FileLengthRule().identifier)].arrayOfInts {
            rules.append(FileLengthRule(parameters: ruleParametersFromArray(params)))
        } else {
            rules.append(FileLengthRule())
        }
        rules.append(TodoRule())
        rules.append(ColonRule())
        rules.append(TypeNameRule())
        rules.append(VariableNameRule())
        if let params = yaml?[.String(TypeBodyLengthRule().identifier)].arrayOfInts {
            rules.append(TypeBodyLengthRule(parameters: ruleParametersFromArray(params)))
        } else {
            rules.append(TypeBodyLengthRule())
        }
        if let params = yaml?[.String(FunctionBodyLengthRule().identifier)].arrayOfInts {
            rules.append(FunctionBodyLengthRule(parameters: ruleParametersFromArray(params)))
        } else {
            rules.append(FunctionBodyLengthRule())
        }
        rules.append(NestingRule())
        rules.append(ControlStatementRule())
        return rules
    }

    public static func ruleParametersFromArray<T>(array: [T]) -> [RuleParameter<T>] {
        return zip([.Warning, .Error], array).map(RuleParameter.init)
    }
}
