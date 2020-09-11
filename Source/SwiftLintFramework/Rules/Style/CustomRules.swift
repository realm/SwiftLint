import Foundation

private extension Region {
    func isRuleDisabled(customRuleIdentifier: String) -> Bool {
        return disabledRuleIdentifiers.contains(RuleIdentifier(customRuleIdentifier))
    }
}

// MARK: - CustomRulesConfiguration

public struct CustomRulesConfiguration: RuleConfiguration, Equatable, CacheDescriptionProvider {
    public var consoleDescription: String { return "user-defined" }
    internal var cacheDescription: String {
        return customRuleConfigurations
            .sorted { $0.identifier < $1.identifier }
            .map { $0.cacheDescription }
            .joined(separator: "\n")
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        var configurations = configuration.customRuleConfigurations

        guard !configurations.isEmpty else {
            return []
        }

        if let path = file.path {
            let pathRange = path.fullNSRange
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
            let captureGroup = configuration.captureGroup
            let excludingKinds = configuration.excludedMatchKinds
            return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds, captureGroup: captureGroup).map({
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
