import SwiftSyntax

public struct ReduceBooleanRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "reduce_boolean",
        name: "Reduce Boolean",
        description: "Prefer using `.allSatisfy()` or `.contains()` over `reduce(true)` or `reduce(false)`",
        kind: .performance,
        nonTriggeringExamples: [
            Example("nums.reduce(0) { $0.0 + $0.1 }"),
            Example("nums.reduce(0.0) { $0.0 + $0.1 }")
        ],
        triggeringExamples: [
            Example("let allNines = nums.↓reduce(true) { $0.0 && $0.1 == 9 }"),
            Example("let anyNines = nums.↓reduce(false) { $0.0 || $0.1 == 9 }"),
            Example("let allValid = validators.↓reduce(true) { $0 && $1(input) }"),
            Example("let anyValid = validators.↓reduce(false) { $0 || $1(input) }"),
            Example("let allNines = nums.↓reduce(true, { $0.0 && $0.1 == 9 })"),
            Example("let anyNines = nums.↓reduce(false, { $0.0 || $0.1 == 9 })"),
            Example("let allValid = validators.↓reduce(true, { $0 && $1(input) })"),
            Example("let anyValid = validators.↓reduce(false, { $0 || $1(input) })")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        Visitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.violations)
            .map { violation in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, position: violation.position),
                               reason: violation.reason)
            }
    }
}

private extension ReduceBooleanRule {
    struct Violation {
        let position: AbsolutePosition
        let reason: String
    }

    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violations: [Violation] = []
        var violationPositions: [AbsolutePosition] { violations.map(\.position) }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard
                let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self),
                calledExpression.name.text == "reduce",
                let firstArgument = node.argumentList.first,
                let bool = firstArgument.expression.as(BooleanLiteralExprSyntax.self)
            else {
                return
            }

            let suggestedFunction = bool.booleanLiteral.tokenKind == .trueKeyword ? "allSatisfy" : "contains"
            violations.append(
                Violation(
                    position: calledExpression.name.positionAfterSkippingLeadingTrivia,
                    reason: "Use `\(suggestedFunction)` instead"
                )
            )
        }
    }
}
