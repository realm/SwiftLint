import Foundation

// MARK: - CustomRulesConfiguration

struct CustomRulesConfiguration: RuleConfiguration, CacheDescriptionProvider {
    typealias Parent = CustomRules

    var parameterDescription: RuleConfigurationDescription? { RuleConfigurationOption.noOptions }
    var cacheDescription: String {
        let configsDescription = customRuleConfigurations
            .sorted { $0.identifier < $1.identifier }
            .map(\.cacheDescription)
            .joined(separator: "\n")

        if let defaultMode = defaultExecutionMode {
            return "default_execution_mode:\(defaultMode.rawValue)\n\(configsDescription)"
        }
        return configsDescription
    }
    var customRuleConfigurations = [RegexConfiguration<Parent>]()
    var defaultExecutionMode: RegexConfiguration<Parent>.ExecutionMode?

    mutating func apply(configuration: Any) throws(Issue) {
        guard let configurationDict = configuration as? [String: Any] else {
            throw .invalidConfiguration(ruleID: Parent.identifier)
        }

        // Parse default execution mode if present
        if let defaultModeString = configurationDict["default_execution_mode"] as? String {
            guard let mode = RegexConfiguration<Parent>.ExecutionMode(rawValue: defaultModeString) else {
                throw Issue.invalidConfiguration(ruleID: Parent.identifier)
            }
            defaultExecutionMode = mode
        }

        for (key, value) in configurationDict where key != "default_execution_mode" {
            var ruleConfiguration = RegexConfiguration<Parent>(identifier: key)

            do {
                try ruleConfiguration.apply(configuration: value)
            } catch {
                Issue.invalidConfiguration(ruleID: key).print()
                continue
            }

            customRuleConfigurations.append(ruleConfiguration)
        }
        customRuleConfigurations.sort { $0.identifier < $1.identifier }
    }
}

// MARK: - CustomRules

@DisabledWithoutSourceKit
struct CustomRules: Rule, CacheDescriptionProvider, ConditionallySourceKitFree {
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
            the severity level, and what message to display. Rules default to SwiftSyntax mode for improved \
            performance. Use `execution_mode: sourcekit` or `default_execution_mode: sourcekit` for SourceKit mode.
            """,
        kind: .style)

    var configuration = CustomRulesConfiguration()

    /// Returns true if all configured custom rules use SwiftSyntax mode, making this rule effectively SourceKit-free.
    var isEffectivelySourceKitFree: Bool {
        configuration.customRuleConfigurations.allSatisfy { config in
            let effectiveMode = config.executionMode == .default
                ? (configuration.defaultExecutionMode ?? .sourcekit)
                : config.executionMode
            return effectiveMode == .swiftsyntax
        }
    }

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

    func canBeDisabled(violation: StyleViolation, by ruleID: RuleIdentifier) -> Bool {
        switch ruleID {
        case let .single(identifier: id):
            id == Self.identifier
                ? customRuleIdentifiers.contains(violation.ruleIdentifier)
                : customRuleIdentifiers.contains(id) && violation.ruleIdentifier == id
        default:
            (self as any Rule).canBeDisabled(violation: violation, by: ruleID)
        }
    }

    func isEnabled(in region: Region, for ruleID: String) -> Bool {
        if !Self.description.allIdentifiers.contains(ruleID),
           !customRuleIdentifiers.contains(ruleID),
           Self.identifier != ruleID {
            return true
        }
        return !region.disabledRuleIdentifiers.contains(RuleIdentifier(Self.identifier))
            && !region.disabledRuleIdentifiers.contains(RuleIdentifier(ruleID))
            && !region.disabledRuleIdentifiers.contains(.all)
    }
}
