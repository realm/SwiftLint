import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: true)
struct IdenticalOperandsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    private static let operators = ["==", "!=", "===", "!==", ">", ">=", "<", "<="]

    static let description = RuleDescription(
        identifier: "identical_operands",
        name: "Identical Operands",
        description: "Comparing two identical operands is likely a mistake",
        kind: .lint,
        nonTriggeringExamples: operators.flatMap { operation in
            #examples([
                "1 \(operation) 2",
                "foo \(operation) bar",
                "prefixedFoo \(operation) foo",
                "foo.aProperty \(operation) foo.anotherProperty",
                "self.aProperty \(operation) self.anotherProperty",
                "\"1 \(operation) 1\"",
                "self.aProperty \(operation) aProperty",
                "lhs.aProperty \(operation) rhs.aProperty",
                "lhs.identifier \(operation) rhs.identifier",
                "i \(operation) index",
                "$0 \(operation) 0",
                "keyValues?.count ?? 0 \(operation) 0",
                "string \(operation) string.lowercased()",
                """
                let num: Int? = 0
                _ = num != nil && num \(operation) num?.byteSwapped
                """,
                "num \(operation) num!.byteSwapped",
                "1    + 1 \(operation)   1     +    2",
                "f(  i :   2) \(operation)   f (i: 3 )",
            ])
        } + #examples([
            "func evaluate(_ mode: CommandMode) -> Result<Options, CommandantError<CommandantError<()>>>",
            "let array = Array<Array<Int>>()",
            "guard Set(identifiers).count != identifiers.count else { return }",
            #"expect("foo") == "foo""#,
            "type(of: model).cachePrefix == cachePrefix",
            "histogram[156].0 == 0x003B8D96 && histogram[156].1 == 1",
            #"[Wrapper(type: .three), Wrapper(type: .one)].sorted { "\($0.type)" > "\($1.type)"}"#,
            #"array.sorted { "\($0)" < "\($1)" }"#,
        ]),
        triggeringExamples: operators.flatMap { operation in
            #examples([
                "↓1 \(operation) 1",
                "↓foo \(operation) foo",
                "↓foo.aProperty \(operation) foo.aProperty",
                "↓self.aProperty \(operation) self.aProperty",
                "↓$0 \(operation) $0",
                "↓a?.b \(operation) a?.b",
                "if (↓elem \(operation) elem) {}",
                "XCTAssertTrue(↓s3 \(operation) s3)",
                "if let tab = tabManager.selectedTab, ↓tab.webView \(operation) tab.webView",
                "↓1    + 1 \(operation)   1     +    1",
                " ↓f(  i :   2) \(operation)   f (i: \n 2 )",
            ])
        } + #examples([
            """
                return ↓lhs.foo == lhs.foo &&
                       lhs.bar == rhs.bar
            """,
            """
                return lhs.foo == rhs.foo &&
                       ↓lhs.bar == lhs.bar
            """,
        ])
    )
}

private extension IdenticalOperandsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let operatorNode = node.operator.as(BinaryOperatorExprSyntax.self),
                  IdenticalOperandsRule.operators.contains(operatorNode.operator.text) else {
                return
            }

            if node.leftOperand.normalizedDescription == node.rightOperand.normalizedDescription {
                violations.append(node.leftOperand.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ExprSyntax {
    var normalizedDescription: String {
        debugDescription(includeTrivia: false)
    }
}
