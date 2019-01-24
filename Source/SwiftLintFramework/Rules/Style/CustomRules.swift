import Foundation
import SourceKittenFramework

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

public struct CustomRules: CorrectableRule, ConfigurationProviderRule, CacheDescriptionProvider {
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

    internal func configurations(file: File) -> [RegexConfiguration] {
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

        return configurations
    }

    public func validate(file: File) -> [StyleViolation] {
        let configurations = self.configurations(file: file)
        return configurations.flatMap { configuration in
            return configuration.violatingRanges(inFile: file).map {
                StyleViolation(ruleDescription: configuration.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location),
                               reason: configuration.message)
            }
        }
    }

    public func correct(file: File) -> [Correction] {
        let configurations = self.configurations(file: file)

        var correctedContents = file.contents
        var corrections = [Correction]()

        for configuration in configurations {
            guard let correction = configuration.correction else {
                continue
            }
            let violatingRanges = configuration.violatingRanges(inFile: file)

            for violatingRange in violatingRanges.reversed() {
                correctedContents = regex(configuration.regex.pattern)
                    .stringByReplacingMatches(in: correctedContents, options: [],
                                              range: violatingRange,
                                              withTemplate: correction)
                let location = Location(file: file, characterOffset: violatingRange.location)
                corrections.append(Correction(ruleDescription: configuration.description,
                                              location: location))
            }

            file.write(correctedContents)
        }

        corrections.reverse()
        corrections.sort { lhs, rhs in lhs.location < rhs.location }

        return corrections
    }
}

extension RegexConfiguration {
    func violatingRanges(inFile file: File) -> [NSRange] {
        let excludingSyntaxKinds = SyntaxKind.allKinds.subtracting(syntaxKinds)
        let pattern = regex.pattern
        let excludingPattern = excludeRegex?.pattern

        let matches: [NSRange]
        if let excludingPattern = excludingPattern {
            matches = file.match(pattern: pattern,
                                 excludingSyntaxKinds: excludingSyntaxKinds,
                                 excludingPattern: excludingPattern)
        } else {
            matches = file.match(pattern: pattern,
                                 excludingSyntaxKinds: excludingSyntaxKinds)
        }

        return matches.filter { isRuleEnabled(file: file, inRange: $0) }
    }

    private func isRuleEnabled(file: File, inRange range: NSRange) -> Bool {
        let location = Location(file: file, characterOffset: range.location)
        guard let region = file.regions().first(where: { $0.contains(location) }) else {
            return true
        }
        return !region.isRuleDisabled(customRuleIdentifier: identifier)
    }
}
