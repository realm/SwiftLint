import SourceKittenFramework
import SwiftSyntax

public struct ForceCastRule: SyntaxVisitorRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.error)

    public init() {}

    public static let description = RuleDescription(
        identifier: "force_cast",
        name: "Force Cast",
        description: "Force casts should be avoided.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("NSNumber() as? Int\n")
        ],
        triggeringExamples: [ Example("NSNumber() ↓as! Int\n") ]
    )

    @SyntaxVisitorRuleValidatorBuilder
    public var validator: SyntaxVisitorRuleValidator {
        DownCast().form(.forced)
    }
}
