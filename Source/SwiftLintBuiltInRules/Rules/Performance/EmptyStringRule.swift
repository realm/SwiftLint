import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct EmptyStringRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "empty_string",
        name: "Empty String",
        description: "Prefer checking `isEmpty` over comparing `string` to an empty string literal",
        kind: .performance,
        nonTriggeringExamples: [
            Example("myString.isEmpty"),
            Example("!myString.isEmpty"),
            Example("\"\"\"\nfoo==\n\"\"\""),
            Example("""
                func expect<T>(_ value: T) -> T { value }
                let outputText = 1
                _ = expect(outputText) == ""
                """),
        ],
        triggeringExamples: [
            Example(#"myString↓ == """#),
            Example(#"myString↓ != """#),
            Example(#"myString↓=="""#),
            Example(##"myString↓ == #""#"##),
            Example(###"myString↓ == ##""##"###),
        ]
    )
}

private extension EmptyStringRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard node.operator.isEqualityComparisonOperator,
                  let rhs = node.rightOperand.as(StringLiteralExprSyntax.self),
                  rhs.isEmptyString,
                  node.leftOperand.isPlausibleStringEmptyCheckOperand else {
                return
            }

            violations.append(node.leftOperand.endPositionBeforeTrailingTrivia)
        }
    }
}

private extension ExprSyntax {
    var isEqualityComparisonOperator: Bool {
        `as`(BinaryOperatorExprSyntax.self)?.operator.tokenKind.isEqualityComparison == true
    }

    var isPlausibleStringEmptyCheckOperand: Bool {
        if `as`(FunctionCallExprSyntax.self) != nil {
            return false
        }

        if `as`(InfixOperatorExprSyntax.self) != nil {
            return false
        }

        if `as`(TupleExprSyntax.self) != nil {
            return false
        }

        if `as`(SequenceExprSyntax.self) != nil {
            return false
        }

        if `as`(TernaryExprSyntax.self) != nil {
            return false
        }

        return `as`(DeclReferenceExprSyntax.self) != nil
            || `as`(MemberAccessExprSyntax.self) != nil
            || `as`(OptionalChainingExprSyntax.self) != nil
    }
}
