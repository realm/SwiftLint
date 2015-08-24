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
}

public struct Configuration {
    public let disabledRules: [String] // disabled_rules
    public let included: [String]      // included
    public let excluded: [String]      // excluded

    public var rules: [Rule] {
        return allRules.filter { !disabledRules.contains($0.identifier) }
    }

    public init?(disabledRules: [String] = [], included: [String] = [], excluded: [String] = []) {
        self.disabledRules = disabledRules
        self.included = included
        self.excluded = excluded

        // Validate that all rule identifiers map to a defined rule

        let validRuleIdentifiers = allRules.map { $0.identifier }

        let ruleSet = Set(disabledRules)
        let invalidRules = ruleSet.filter({ !validRuleIdentifiers.contains($0) })
        if invalidRules.count > 0 {
            for invalidRule in invalidRules {
                fputs("config error: '\(invalidRule)' is not a valid rule identifier\n", stderr)
                let listOfValidRuleIdentifiers = "\n".join(validRuleIdentifiers)
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
    }

    public init?(yaml: String) {
        guard let yamlConfig = Yaml.load(yaml).value else {
            return nil
        }
        self.init(
            disabledRules: yamlConfig["disabled_rules"].arrayOfStrings ?? [],
            included: yamlConfig["included"].arrayOfStrings ?? [],
            excluded: yamlConfig["excluded"].arrayOfStrings ?? []
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
}
