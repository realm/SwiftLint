import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true)
struct TextConcatenationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "text_concatenation",
        name: "SwiftUI.Text Concatenation",
        description: "Avoid concatenating SwiftUI.Text instances",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                Text(string)
            """),
            Example(#"Text("wow \(wowee)")"#),
            Example("""
                HStack {
                    Text("foo")
                    Text("bar")
                }
            """)
        ],
        triggeringExamples: [
            Example("""
                Text("bar") ↓+ Text("foo")
            """),
            Example("""
            Text("wow")
                .foregroundColor(.blue)
                .font(.heavy)

            ↓+

            Text("wow2")
                .foregroundColor(.black)
         """)
        ]
    )
}

private extension TextConcatenationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard node.operator.as(BinaryOperatorExprSyntax.self)?.operator.text == "+" else { return }

            if recursivelySearchForTextInitializerCall(node.leftOperand) != nil,
               recursivelySearchForTextInitializerCall(node.rightOperand) != nil {
                violations.append(reason(position: node.operator.positionAfterSkippingLeadingTrivia))
            }
        }

        func recursivelySearchForTextInitializerCall(_ node: any ExprSyntaxProtocol) -> FunctionCallExprSyntax? {
            if let funcCall = node.as(FunctionCallExprSyntax.self) {
                let isTextInit = funcCall.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Text"

                if isTextInit {
                    return funcCall
                } else {
                    return recursivelySearchForTextInitializerCall(funcCall.calledExpression)
                }
            } else if let memberAccess = node.as(MemberAccessExprSyntax.self), let base = memberAccess.base {
                return recursivelySearchForTextInitializerCall(base)
            }

            return nil
        }

        func reason(position: AbsolutePosition) -> ReasonedRuleViolation {
            .init(
                position: position,
                reason: """
                Avoid concatenating Swift.Text elements with '+' because it breaks translations. \
                Use AttributedString.init if you need to apply multiple styles inside a single string
                """,
                severity: .warning
            )
        }
    }
}
