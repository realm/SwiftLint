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

public struct CustomRules: ASTRule, ConfigProviderRule {

    public static let description = RuleDescription(
        identifier: "custom_rules",
        name: "Custom Rules",
        description: "Create custom rules by providing a regex string. " +
          "Optionally specify what syntax kinds to match against, the severity " +
          "level, and what message to display")

    public var config = CustomRulesConfig()

    public init() {}

    public func validateFile(file: File,
                             kind: SwiftDeclarationKind,
                             dictionary: XPCDictionary) -> [StyleViolation] {
        return []
    }
}
