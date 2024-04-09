import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true)
struct JSONDecodingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "json_decoding",
        name: "JSON Decoding",
        description: "Don't use JSONDecoder.decode directly",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                T.decode(data)
            """),
            Example("""
                let decoder = JSONDecoder()
                MyType.decode(data, using: decoder)
            """),
            Example("""
                MyType.decode(data, using: JSONDecoder().snakeCase())
            """),
            Example("""
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let myType = try container.decode(MyType.self, forKey: .myType)
            """),
            Example("""
                let container = try decoder.singleValueContainer().decode(MyType.self)
            """)
        ],
        triggeringExamples: [
            Example("""
                JSONDecoder().↓decode(MyType.self, from: data)
            """),
            Example("""
                let decoder = JSONDecoder()
                decoder.↓decode(MyType.self, from: data)
            """),
            Example("""
                JSONDecoder().snakeCase().↓decode(Self.self, from: data)
            """)
        ]
    )
}

private extension JSONDecodingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let member = node.calledExpression.as(MemberAccessExprSyntax.self),
                  member.declName.baseName.text == "decode",
                  let argument = node.arguments.first?.expression.as(MemberAccessExprSyntax.self),
                  let modelName = argument.base?.description,
                  argument.declName.baseName.text == "self",
                  let fromArgument = node.arguments.first(where: { $0.label?.text == "from" })
            else { return }

            violations.append(reason(
                modelName: modelName,
                dataName: fromArgument.expression.description,
                position: member.declName.positionAfterSkippingLeadingTrivia
            ))
        }

        func reason(modelName: String, dataName: String, position: AbsolutePosition) -> ReasonedRuleViolation {
            .init(
                position: position,
                reason: """
                Use `\(modelName).decode(\(dataName))` instead. It will automatically trigger \
                error logs if the decoding fails
                """,
                severity: .warning
            )
        }
    }
}
