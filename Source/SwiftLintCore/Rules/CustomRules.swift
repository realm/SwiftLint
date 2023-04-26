import Foundation

// MARK: - CustomRulesConfiguration

struct CustomRulesConfiguration: RuleConfiguration, Equatable, CacheDescriptionProvider {
    var consoleDescription: String { return "user-defined" }
    var cacheDescription: String {
        return customRuleConfigurations
            .sorted { $0.identifier < $1.identifier }
            .map { $0.cacheDescription }
            .joined(separator: "\n")
    }
    var customRuleConfigurations = [RegexConfiguration]()

    mutating func apply(configuration: Any) throws {
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

struct CustomRules: Rule, ConfigurationProviderRule, CacheDescriptionProvider {
    var cacheDescription: String {
        return configuration.cacheDescription
    }

    static let description = RuleDescription(
        identifier: "custom_rules",
        name: "Custom Rules",
        description: """
            Create custom rules by providing a regex string. Optionally specify what syntax kinds to match against, \
            the severity level, and what message to display.
            """,
        kind: .style)

    var configuration = CustomRulesConfiguration()

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        var configurations = configuration.customRuleConfigurations

        guard configurations.isNotEmpty else {
            return []
        }

        if let path = file.path {
            configurations = configurations.filter { config in
                config.shouldValidate(filePath: path)
            }
        }

        return configurations.flatMap { configuration -> [StyleViolation] in
            let start = Date()
            defer {
                CustomRuleTimer.shared.register(time: -start.timeIntervalSinceNow, forRuleID: configuration.identifier)
            }

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

private extension Region {
    func isRuleDisabled(customRuleIdentifier: String) -> Bool {
        return disabledRuleIdentifiers.contains(RuleIdentifier(customRuleIdentifier))
    }
}
