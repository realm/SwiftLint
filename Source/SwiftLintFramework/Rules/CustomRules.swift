import Foundation
import SourceKittenFramework

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

    mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw Issue.invalidConfiguration(ruleID: Parent.identifier)
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
    }
}

// MARK: - CustomRules

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
                ? (configuration.defaultExecutionMode ?? .swiftsyntax)
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

            // Determine effective execution mode (defaults to swiftsyntax if not specified)
            let effectiveMode = configuration.executionMode == .default
                ? (self.configuration.defaultExecutionMode ?? .swiftsyntax)
                : configuration.executionMode
            let needsKindMatching = !excludingKinds.isEmpty

            let matches: [NSRange]
            if effectiveMode == .swiftsyntax {
                if needsKindMatching {
                    // SwiftSyntax mode WITH kind filtering
                    // CRITICAL: This path must not trigger any SourceKit requests
                    guard let bridgedTokens = file.swiftSyntaxDerivedSourceKittenTokens else {
                        // Log error/warning: Bridging failed
                        queuedPrintError(
                            "Warning: SwiftSyntax bridging failed for custom rule '\(configuration.identifier)'"
                        )
                        return []
                    }
                    let syntaxMapFromBridgedTokens = SwiftLintSyntaxMap(
                        value: SyntaxMap(tokens: bridgedTokens.map(\.value))
                    )

                    // Use the performMatchingWithSyntaxMap helper that operates on stringView and syntaxMap ONLY
                    matches = performMatchingWithSyntaxMap(
                        stringView: file.stringView,
                        syntaxMap: syntaxMapFromBridgedTokens,
                        pattern: pattern,
                        excludingSyntaxKinds: excludingKinds,
                        captureGroup: captureGroup
                    )
                } else {
                    // SwiftSyntax mode WITHOUT kind filtering
                    // This path must not trigger any SourceKit requests
                    matches = file.stringView.match(pattern: pattern, captureGroup: captureGroup)
                }
            } else {
                // SourceKit mode
                // SourceKit calls ARE EXPECTED AND PERMITTED here because CustomRules is not SourceKitFreeRule
                matches = file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds, captureGroup: captureGroup)
            }

            return matches.map({
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

// MARK: - Helpers

private func performMatchingWithSyntaxMap(
    stringView: StringView,
    syntaxMap: SwiftLintSyntaxMap,
    pattern: String,
    excludingSyntaxKinds: Set<SyntaxKind>,
    captureGroup: Int
) -> [NSRange] {
    // This helper method must not access any part of SwiftLintFile that could trigger SourceKit requests
    // It operates only on the provided stringView and syntaxMap

    let regex = regex(pattern)
    let range = stringView.range
    let matches = regex.matches(in: stringView, options: [], range: range)

    return matches.compactMap { match in
        let matchRange = match.range(at: captureGroup)

        // Get tokens in the match range
        guard let byteRange = stringView.NSRangeToByteRange(
            start: matchRange.location,
            length: matchRange.length
        ) else {
            return nil
        }

        let tokensInRange = syntaxMap.tokens(inByteRange: byteRange)
        let kindsInRange = Set(tokensInRange.kinds)

        // Check if any excluded kinds are present
        if excludingSyntaxKinds.isDisjoint(with: kindsInRange) {
            return matchRange
        }

        return nil
    }
}
