//
//  CustomRules.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
import SwiftXPC

// MARK: - CustomRulesConfig

public struct CustomRulesConfig: RuleConfig, Equatable {
    var customRuleConfigs = [RegexConfig]()

    public mutating func setConfig(config: AnyObject) throws {
        guard let configDict = config as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        for (key, value) in configDict {
            var ruleConfig = RegexConfig(identifier: key)
            try ruleConfig.setConfig(value)
            customRuleConfigs.append(ruleConfig)
        }
    }
}

public func == (lhs: CustomRulesConfig, rhs: CustomRulesConfig) -> Bool {
    return lhs.customRuleConfigs == rhs.customRuleConfigs
}

// MARK: - CustomRules

public struct CustomRules: Rule, ConfigProviderRule {

    public static let description = RuleDescription(
        identifier: "custom_rules",
        name: "Custom Rules",
        description: "Create custom rules by providing a regex string. " +
          "Optionally specify what syntax kinds to match against, the severity " +
          "level, and what message to display")

    public var config = CustomRulesConfig()

    public init() {}

    public func validateFile(file: File) -> [StyleViolation] {
        guard !config.customRuleConfigs.isEmpty else {
            return []
        }

        var violations = [StyleViolation]()
        for customRule in config.customRuleConfigs {
            // TODO: Flatmap
            violations.appendContentsOf(validate(file, withConfig: customRule))
        }

        return violations
    }

    private func validate(file: File, withConfig config: RegexConfig) -> [StyleViolation] {
        // We are not using the preconstucted regex due to the API available, but it is important
        // to still construct it at configuration parsing time to catch errors.
        let ranges = file.matchPattern(config.regex.pattern, withSyntaxKinds: config.matchTokens)
        let violations = ranges.map {
            StyleViolation(ruleDescription: config.description,
                // TODO: Maybe rename severity to value?
                severity: config.severity.severity,
                location: Location(file: file, characterOffset: $0.location),
                reason: config.message)
        }
        return violations
    }
}
