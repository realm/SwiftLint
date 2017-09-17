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
    func isRuleDisabled(customRuleIdentifier: String) -> Bool {
        return disabledRuleIdentifiers.contains(customRuleIdentifier)
    }
}

// MARK: - CustomRulesConfiguration

public struct CustomRulesConfiguration: RuleConfiguration, Equatable, CacheDescriptionProvider {
    public var consoleDescription: String { return "user-defined" }
    internal var cacheDescription: String {
        return customRuleConfigurations.map({ $0.cacheDescription }).joined(separator: "\n")
    }
    public var customRuleConfigurations = [RegexConfiguration]()

    public init() {}

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        for (key, value) in configurationDict {
            var ruleConfiguration = RegexConfiguration(identifier: key)

            do {
                try ruleConfiguration.apply(configuration: value)
            } catch {
                queuedPrintError("Invalid configuration for custom rule '\(key)'.")
                continue
            }

            customRuleConfigurations.append(ruleConfiguration)
        }
    }
}

public func == (lhs: CustomRulesConfiguration, rhs: CustomRulesConfiguration) -> Bool {
    return lhs.customRuleConfigurations == rhs.customRuleConfigurations
}

// MARK: - CustomRules

public struct CustomRules: Rule, ConfigurationProviderRule, CacheDescriptionProvider {

    internal var cacheDescription: String {
        return configuration.cacheDescription
    }

    public static let description = RuleDescription(
        identifier: "custom_rules",
        name: "Custom Rules",
        description: "Create custom rules by providing a regex string. " +
            "Optionally specify what syntax kinds to match against, the severity " +
            "level, and what message to display.",
        kind: .style)

    public var configuration = CustomRulesConfiguration()

    public init() {}

    public func validate(file: File) -> [StyleViolation] {
        var configurations = configuration.customRuleConfigurations

        guard !configurations.isEmpty else {
            return []
        }

        if let path = file.path {
            let pathRange = NSRange(location: 0, length: path.bridge().length)
            configurations = configurations.filter { config in
                let included: Bool
                if let includedRegex = config.included {
                    included = !includedRegex.matches(in: path, options: [], range: pathRange).isEmpty
                } else {
                    included = true
                }
                guard included else {
                    return false
                }
                guard let excludedRegex = config.excluded else {
                    return true
                }
                return excludedRegex.matches(in: path, options: [], range: pathRange).isEmpty
            }
        }

        return configurations.flatMap { configuration -> [StyleViolation] in
            let pattern = configuration.regex.pattern
            let excludingKinds = SyntaxKind.allKinds.subtracting(configuration.matchKinds)
            return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map({
                StyleViolation(ruleDescription: configuration.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location),
                               reason: configuration.message)
            }).filter { violation in
                guard let region = file.regions().first(where: { $0.contains(violation.location) }) else {
                    return true
                }

                return !region.isRuleDisabled(customRuleIdentifier: configuration.identifier)
            }
        }
    }
}
