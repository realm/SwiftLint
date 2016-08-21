//
//  CustomRules.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private extension Region {
    func isRuleDisabled(customRuleIdentifier customRuleIdentifier: String) -> Bool {
        return disabledRuleIdentifiers.contains(customRuleIdentifier)
    }
}

// MARK: - CustomRulesConfiguration

public struct CustomRulesConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String { return "user-defined" }
    public var customRuleConfigurations = [RegexConfiguration]()

    public init() {}

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configurationDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        for (key, value) in configurationDict {
            var ruleConfiguration = RegexConfiguration(identifier: key)
            try ruleConfiguration.applyConfiguration(value)
            customRuleConfigurations.append(ruleConfiguration)
        }
    }
}

public func == (lhs: CustomRulesConfiguration, rhs: CustomRulesConfiguration) -> Bool {
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

    public var configuration = CustomRulesConfiguration()

    public init() {}

    public func validateFile(file: File) -> [StyleViolation] {
        var configurations = configuration.customRuleConfigurations

        if configurations.isEmpty {
            return []
        }

        if let path = file.path {
            configurations = configurations.filter { config in
                let pattern = config.included.pattern
                if pattern.isEmpty { return true }

                let pathMatch = config.included.matchesInString(path, options: [],
                    range: NSRange(location: 0, length: (path as NSString).length))

                return !pathMatch.isEmpty
            }
        }

        return configurations.flatMap {
            self.validate(file, configuration: $0).filter { eachViolation in
                let regions = file.regions().filter {
                    $0.contains(eachViolation.location)
                }
                guard let region = regions.first else { return true }

                for eachConfig in configurations where
                    region.isRuleDisabled(customRuleIdentifier: eachConfig.identifier) {
                    return false
                }
                return true
            }
        }
    }

    private func validate(file: File, configuration: RegexConfiguration) -> [StyleViolation] {
        let pattern = configuration.regex.pattern
        let excludingKinds = Array(Set(SyntaxKind.allKinds()).subtract(configuration.matchKinds))
        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: configuration.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location),
                reason: configuration.message)
        }
    }
}
