import Foundation
import SourceKittenFramework

public struct LegacyConstantRule: CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_constant",
        name: "Legacy Constant",
        description: "Struct-scoped constants are preferred over legacy global constants.",
        kind: .idiomatic,
        nonTriggeringExamples: LegacyConstantRuleExamples.nonTriggeringExamples,
        triggeringExamples: LegacyConstantRuleExamples.triggeringExamples,
        corrections: LegacyConstantRuleExamples.corrections
    )

    private static let legacyConstants: [String] = {
        return Array(Self.legacyPatterns.keys)
    }()

    private static let legacyPatterns = LegacyConstantRuleExamples.patterns

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "\\b" + Self.legacyConstants.joined(separator: "|")

        return file.match(pattern: pattern, range: nil)
            .filter { Set($0.1).isSubset(of: [.identifier]) }
            .map { $0.0 }
            .map {
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        var wordBoundPatterns: [String: String] = [:]
        Self.legacyPatterns.forEach { key, value in
            wordBoundPatterns["\\b" + key] = value
        }

        return file.correct(legacyRule: self, patterns: wordBoundPatterns)
    }
}
