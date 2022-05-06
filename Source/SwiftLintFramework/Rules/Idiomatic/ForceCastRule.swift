import SourceKittenFramework
import SwiftSyntax

public struct ForceCastRule: ConfigurationProviderRule, AutomaticTestableRule {
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let visitor = ForceCastRuleVisitor()
        return visitor.walk(file: file, handler: \.positions).map { position in
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: ByteCount(position)))
        }
    }
}

private final class ForceCastRuleVisitor: SyntaxVisitor {
    var positions: [AbsolutePosition] = []

    override func visitPost(_ node: AsExprSyntax) {
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            positions.append(node.asTok.positionAfterSkippingLeadingTrivia)
        }
    }
}
