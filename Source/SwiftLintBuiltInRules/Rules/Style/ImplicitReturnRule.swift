import SwiftSyntax

@SwiftSyntaxRule
struct ImplicitReturnRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = ImplicitReturnConfiguration()

    static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures, functions and getters",
        kind: .style,
        nonTriggeringExamples: ImplicitReturnRuleExamples.nonTriggeringExamples,
        triggeringExamples: ImplicitReturnRuleExamples.triggeringExamples,
        corrections: ImplicitReturnRuleExamples.corrections
    )
}

private extension ImplicitReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: AccessorDeclSyntax) {
            if configuration.isKindIncluded(.getter),
               node.accessorSpecifier.tokenKind == .keyword(.get),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if configuration.isKindIncluded(.closure) {
                collectViolation(in: node.statements)
            }
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if configuration.isKindIncluded(.function),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if configuration.isKindIncluded(.initializer),
               let body = node.body {
                collectViolation(in: body.statements)
            }
        }

        override func visitPost(_ node: PatternBindingSyntax) {
            if configuration.isKindIncluded(.getter),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            if configuration.isKindIncluded(.subscript),
               case let .getter(itemList) = node.accessorBlock?.accessors {
                collectViolation(in: itemList)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if configuration.isKindIncluded(.switch) {
                dump(file.syntaxTree)
                var violations: [CodeBlockItemListSyntax] = []
                let switchCases: SwitchCaseListSyntax = node.cases
                for switchCase in switchCases {
                    dump("🏴‍☠️ \(switchCase)")
                    var childViolations: [CodeBlockItemListSyntax] = []
                    if let item = switchCase.as(SwitchCaseSyntax.self) {
                        if item.statements.count > 1 {
                            return
                        } else {
                            childViolations.append(item.statements)
                        }
                    }
                    for violation in childViolations {
                        violations.append(violation)
                    }
                }
//                if node.statements.syntaxNodeType != NilLiteralExprSyntax.self {
//                    if item != "return" && item != "return nil" {
//                        collectViolation(in: node.statements)
//                    }
//                }
                for violation in violations {
                    collectViolation(in: violation)
                }
            }
        }

        private func collectViolation(in itemList: CodeBlockItemListSyntax) {
            guard let returnStmt = itemList.onlyElement?.item.as(ReturnStmtSyntax.self) else {
                return
            }
            let returnKeyword = returnStmt.returnKeyword
            violations.append(
                at: returnKeyword.positionAfterSkippingLeadingTrivia,
                correction: .init(
                    start: returnKeyword.positionAfterSkippingLeadingTrivia,
                    end: returnKeyword.endPositionBeforeTrailingTrivia
                            .advanced(by: returnStmt.expression == nil ? 0 : 1),
                    replacement: ""
                )
            )
        }
    }
}
