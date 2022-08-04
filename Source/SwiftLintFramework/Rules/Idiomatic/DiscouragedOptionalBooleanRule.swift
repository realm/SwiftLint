import Foundation
import SourceKittenFramework

public struct DiscouragedOptionalBooleanRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_optional_boolean",
        name: "Discouraged Optional Boolean",
        description: "Prefer non-optional booleans over optional booleans.",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalBooleanRuleExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalBooleanRuleExamples.triggeringExamples
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let booleanPattern = "Bool\\?"
        let optionalPattern = "Optional\\.some\\(\\s*(true|false)\\s*\\)"
        let pattern = "(" + [booleanPattern, optionalPattern].joined(separator: "|") + ")"
        let excludingKinds = SyntaxKind.commentAndStringKinds

        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
