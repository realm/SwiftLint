//
//  CustomRules.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

// MARK: - CustomRulesConfig

public struct CustomRulesConfig: RuleConfiguration, Equatable {
    public var consoleDescription: String { return "user-defined" }
    public var customRuleConfigurations = [RegexConfig]()

    public init() {}

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configurationDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        for (key, value) in configurationDict {
            var ruleConfiguration = RegexConfig(identifier: key)
            try ruleConfiguration.applyConfiguration(value)
            customRuleConfigurations.append(ruleConfiguration)
        }
    }
}

public func == (lhs: CustomRulesConfig, rhs: CustomRulesConfig) -> Bool {
    return lhs.customRuleConfigurations == rhs.customRuleConfigurations
}

// MARK: - CustomRules

public struct CustomRules: Rule, ConfigurationProviderRule {

    public static let description = RuleDescription(
        identifier: "custom_rules",
        name: "Custom Rules",
        description: "Create custom rules by providing a regex string. " +
          "Optionally specify what syntax kinds to match against, the severity " +
          "level, and what message to display.")

    public var configuration = CustomRulesConfig()

    public init() {}

    public func validateFile(file: File) -> [StyleViolation] {
        if configuration.customRuleConfigurations.isEmpty {
            return []
        }

        return configuration.customRuleConfigurations.flatMap {
            self.validate(file, configuration: $0)
        }
    }

    private func validate(file: File, configuration: RegexConfig) -> [StyleViolation] {
        return file.matchPattern(configuration.regex).filter {
            !configuration.matchKinds.intersect($0.1).isEmpty
        }.map {
            StyleViolation(ruleDescription: configuration.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.0.location),
                reason: configuration.message)
        }
    }
}
