import Foundation

// MARK: - CustomRulesConfiguration

struct CustomRulesConfiguration: RuleConfiguration, CacheDescriptionProvider {
    typealias Parent = CustomRules

    var parameterDescription: RuleConfigurationDescription? { RuleConfigurationOption.noOptions }
    var cacheDescription: String {
        customRuleConfigurations
            .sorted { $0.identifier < $1.identifier }
            .map(\.cacheDescription)
            .joined(separator: "\n")
    }
    var customRuleConfigurations = [RegexConfiguration<Parent>]()

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
        }

        for (key, value) in configurationDict {
            var ruleConfiguration = RegexConfiguration<Parent>(identifier: key)

            do {
                try ruleConfiguration.apply(configuration: value)
            } catch {
                Issue.invalidConfiguration(ruleID: key).print()
                continue
            }

            customRuleConfigurations.append(ruleConfiguration)
        }
    }
}

// MARK: - CustomRules

struct CustomRules: Rule, CacheDescriptionProvider {
    var cacheDescription: String {
        configuration.cacheDescription
    }

    var customRuleIdentifiers: [String] {
        configuration.customRuleConfigurations.map(\.identifier)
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
            })
        }
    }

    func disabledRuleIdentifiersWithRegions(regions: [Region]) -> [(String, [Region])] {
        var result = configuration.customRuleConfigurations.map { configuration in
            let regionsDisablingCurrentRule = regions.filter { region in
                region.disabledRuleIdentifiers.contains(RuleIdentifier(configuration.identifier))
            }
            return (configuration.identifier, regionsDisablingCurrentRule)
        }
        let regionsDisablingAllCustomRules = regions.filter(\.areAllCustomRulesDisabled)
        if regionsDisablingAllCustomRules.isNotEmpty {
            result.append((Self.description.identifier, regionsDisablingAllCustomRules))
        }
        return result
    }
}

extension Region {
    func isCustomRuleDisabled(customRuleIdentifier: String) -> Bool {
           areAllCustomRulesDisabled
        || isCustomRuleSpecificallyDisabled(customRuleIdentifier: customRuleIdentifier)
        || disabledRuleIdentifiers.contains(.all)
    }

    func isCustomRuleSpecificallyDisabled(customRuleIdentifier: String) -> Bool {
        disabledRuleIdentifiers.contains(RuleIdentifier(customRuleIdentifier))
    }

    var areAllCustomRulesDisabled: Bool {
        disabledRuleIdentifiers.contains(RuleIdentifier(CustomRules.description.identifier))
    }
}
