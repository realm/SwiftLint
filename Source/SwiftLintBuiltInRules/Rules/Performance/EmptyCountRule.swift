import SwiftLexicalLookup
import SwiftLintCore
import SwiftSyntax
import SwiftSyntaxBuilder

@SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true, optIn: true)
struct EmptyCountRule: Rule {
    var configuration = EmptyCountConfiguration()

    static let description = RuleDescription(
        identifier: "empty_count",
        name: "Empty Count",
        description: "Prefer checking `isEmpty` over comparing `count` to zero",
        kind: .performance,
        nonTriggeringExamples: #examples([
            "var count = 0",
            "[Int]().isEmpty",
            "[Int]().count > 1",
            "[Int]().count == 1",
            "[Int]().count == 0xff",
            "[Int]().count == 0b01",
            "[Int]().count == 0o07",
            "discount == 0",
            "order.discount == 0",
            "let rule = #Rule(Tips.Event(id: \"someTips\")) { $0.donations.count == 0 }",
            "#Rule(param1: \"param1\")".excludeFromDocumentation(),
            "func isEmpty(count: Int) -> Bool { count == 0 }",
            """
                var isEmpty: Bool {
                    let count = 0
                    return count == 0
                }
                """,
            "{ count in count == 0 }()",
        ]),
        triggeringExamples: #examples([
            "[Int]().↓count == 0",
            "0 == [Int]().↓count",
            "[Int]().↓count==0",
            "[Int]().↓count > 0",
            "[Int]().↓count != 0",
            "[Int]().↓count == 0x0",
            "[Int]().↓count == 0x00_00",
            "[Int]().↓count == 0b00",
            "[Int]().↓count == 0o00",
            "↓count == 0",
            "#ExampleMacro { $0.list.↓count == 0 }",
            "#Rule { $0.donations.↓count == 0 }".excludeFromDocumentation(),
            "#Rule(param1: \"param1\", param2: \"param2\") { $0.donations.↓count == 0 }".excludeFromDocumentation(),
            "#Rule(param1: \"param1\") { $0.donations.↓count == 0 } closure2: { doSomething() }"
                .excludeFromDocumentation(),
            "#Rule(param1: \"param1\") { return $0.donations.↓count == 0 }".excludeFromDocumentation(),
            """
                #Rule(param1: "param1") {
                    doSomething()
                    return $0.donations.↓count == 0
                }
                """.excludeFromDocumentation(),
            """
                extension E {
                    var isEmpty: Bool { ↓count == 0 }
                }
                """.excludeFromDocumentation(),
            """
                struct S {
                    var isEmpty: Bool { ↓count == 0 }
                }
                """.excludeFromDocumentation(),
        ]),
        corrections: #examplesDictionary([
            "[].↓count == 0":
                "[].isEmpty",
            "0 == [].↓count":
                "[].isEmpty",
            "[Int]().↓count == 0":
                "[Int]().isEmpty",
            "0 == [Int]().↓count":
                "[Int]().isEmpty",
            "[Int]().↓count==0":
                "[Int]().isEmpty",
            "[Int]().↓count > 0":
                "![Int]().isEmpty",
            "[Int]().↓count != 0":
                "![Int]().isEmpty",
            "[Int]().↓count == 0x0":
                "[Int]().isEmpty",
            "[Int]().↓count == 0x00_00":
                "[Int]().isEmpty",
            "[Int]().↓count == 0b00":
                "[Int]().isEmpty",
            "[Int]().↓count == 0o00":
                "[Int]().isEmpty",
            "↓count == 0":
                "isEmpty",
            "↓count == 0 && [Int]().↓count == 0o00":
                "isEmpty && [Int]().isEmpty",
            "[Int]().count != 3 && [Int]().↓count != 0 || ↓count == 0 && [Int]().count > 2":
                "[Int]().count != 3 && ![Int]().isEmpty || isEmpty && [Int]().count > 2",
            "#ExampleMacro { $0.list.↓count == 0 }":
                "#ExampleMacro { $0.list.isEmpty }",
            "#Rule(param1: \"param1\") { return $0.donations.↓count == 0 }":
                "#Rule(param1: \"param1\") { return $0.donations.isEmpty }",
        ])
    )
}

private extension EmptyCountRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let binaryOperator = node.binaryOperator, binaryOperator.isComparison else {
                return
            }

            if let (_, position) = node.countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot) {
                violations.append(position)
            }
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
            node.isTipsRuleMacro ? .skipChildren : .visitChildren
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard let binaryOperator = node.binaryOperator, binaryOperator.isComparison else {
                return super.visit(node)
            }

            if let (count, _) = node.countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot) {
                let newNode =
                    if let count = count.as(MemberAccessExprSyntax.self) {
                        ExprSyntax(count.with(\.declName.baseName, "isEmpty").trimmed)
                    } else {
                        ExprSyntax(count.as(DeclReferenceExprSyntax.self)?.with(\.baseName, "isEmpty").trimmed)
                    }
                guard let newNode else {
                    return super.visit(node)
                }
                numberOfCorrections += 1
                return
                    if ["!=", "<", ">"].contains(binaryOperator) {
                        newNode.negated
                            .withTrivia(from: node)
                    } else {
                        newNode
                            .withTrivia(from: node)
                    }
            }
            return super.visit(node)
        }

        override func visit(_ node: MacroExpansionExprSyntax) -> ExprSyntax {
            if node.isTipsRuleMacro {
                ExprSyntax(node)
            } else {
                super.visit(node)
            }
        }
    }
}

private extension ExprSyntax {
    var isNonLocalCountIdentifier: Bool {
        guard let declRef = `as`(DeclReferenceExprSyntax.self),
              declRef.argumentNames == nil,
              declRef.baseName.tokenKind == .identifier("count") else {
            return false
        }
        let result = lookup(Identifier(canonicalName: "count"))
        return result.isEmpty || !result.contains { result in
            switch result {
            case .fromScope: true
            default: false
            }
        }
    }

    func countCallPosition(onlyAfterDot: Bool) -> AbsolutePosition? {
        if let expr = `as`(MemberAccessExprSyntax.self) {
            if expr.declName.argumentNames == nil, expr.declName.baseName.tokenKind == .identifier("count") {
                return expr.declName.baseName.positionAfterSkippingLeadingTrivia
            }
            return nil
        }
        if !onlyAfterDot, isNonLocalCountIdentifier {
            return positionAfterSkippingLeadingTrivia
        }
        return nil
    }
}

private extension TokenSyntax {
    var binaryOperator: String? {
        switch tokenKind {
        case .binaryOperator(let str):
            return str
        default:
            return nil
        }
    }
}

private extension MacroExpansionExprSyntax {
    var isTipsRuleMacro: Bool {
        macroName.text == "Rule" &&
        additionalTrailingClosures.isEmpty &&
        arguments.count == 1 &&
        trailingClosure.map { $0.statements.onlyElement?.item.is(ReturnStmtSyntax.self) == false } ?? false
    }
}

private extension ExprSyntaxProtocol {
    var negated: ExprSyntax {
        ExprSyntax(PrefixOperatorExprSyntax(operator: .prefixOperator("!"), expression: self))
    }
}

private extension SyntaxProtocol {
    func withTrivia(from node: some SyntaxProtocol) -> Self {
        with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
    }
}

private extension InfixOperatorExprSyntax {
    func countNodeAndPosition(onlyAfterDot: Bool) -> (ExprSyntax, AbsolutePosition)? {
        if let intExpr = rightOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
           let position = leftOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
            return (leftOperand, position)
        }
        if let intExpr = leftOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
           let position = rightOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
            return (rightOperand, position)
        }
        return nil
    }

    var binaryOperator: String? {
        `operator`.as(BinaryOperatorExprSyntax.self)?.operator.binaryOperator
    }
}

private extension String {
    private static let operators: Set = ["==", "!=", ">", ">=", "<", "<="]
    var isComparison: Bool {
        Self.operators.contains(self)
    }
}
