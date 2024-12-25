import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct JoinedDefaultParameterRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "joined_default_parameter",
        name: "Joined Default Parameter",
        description: "Discouraged explicit usage of the default separator",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let foo = bar.joined()"),
            Example("let foo = bar.joined(separator: \",\")"),
            Example("let foo = bar.joined(separator: toto)"),
        ],
        triggeringExamples: [
            Example("let foo = bar.joined(↓separator: \"\")"),
            Example("""
            let foo = bar.filter(toto)
                         .joined(↓separator: ""),
            """),
            Example("""
            func foo() -> String {
              return ["1", "2"].joined(↓separator: "")
            }
            """),
        ],
        corrections: [
            Example("let foo = bar.joined(↓separator: \"\")"): Example("let foo = bar.joined()"),
            Example("let foo = bar.filter(toto)\n.joined(↓separator: \"\")"):
                Example("let foo = bar.filter(toto)\n.joined()"),
            Example("func foo() -> String {\n   return [\"1\", \"2\"].joined(↓separator: \"\")\n}"):
                Example("func foo() -> String {\n   return [\"1\", \"2\"].joined()\n}"),
            Example("class C {\n#if true\nlet foo = bar.joined(↓separator: \"\")\n#endif\n}"):
                Example("class C {\n#if true\nlet foo = bar.joined()\n#endif\n}"),
        ]
    )
}

private extension JoinedDefaultParameterRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let violationPosition = node.violationPosition {
                violations.append(violationPosition)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard let violationPosition = node.violationPosition else {
                return super.visit(node)
            }
            correctionPositions.append(violationPosition)
            let newNode = node.with(\.arguments, [])
            return super.visit(newNode)
        }
    }
}

private extension FunctionCallExprSyntax {
    var violationPosition: AbsolutePosition? {
        guard let argument = arguments.first,
              let memberExp = calledExpression.as(MemberAccessExprSyntax.self),
              memberExp.declName.baseName.text == "joined",
              argument.label?.text == "separator",
              let strLiteral = argument.expression.as(StringLiteralExprSyntax.self),
              strLiteral.isEmptyString else {
            return nil
        }

        return argument.positionAfterSkippingLeadingTrivia
    }
}
