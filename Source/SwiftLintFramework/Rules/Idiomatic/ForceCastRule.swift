import SwiftSyntax

public struct ForceCastRule: ConfigurationProviderRule, SwiftSyntaxRule {
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        ForceCastRuleVisitor(viewMode: .sourceAccurate)
    }
}

private final class ForceCastRuleVisitor: ViolationsSyntaxVisitor {
    override func visitPost(_ node: AsExprSyntax) {
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            violationPositions.append(node.asTok.positionAfterSkippingLeadingTrivia)
        }
    }

    override func visitPost(_ node: UnresolvedAsExprSyntax) {
        if node.questionOrExclamationMark?.tokenKind == .exclamationMark {
            violationPositions.append(node.asTok.positionAfterSkippingLeadingTrivia)
        }
    }
}
