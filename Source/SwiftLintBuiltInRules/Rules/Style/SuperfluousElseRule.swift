import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct SuperfluousElseRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "superfluous_else",
        name: "Superfluous Else",
        description: "Else branches should be avoided when the previous if-block exits the current scope",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                if i > 0 {
                    // comment
                } else if i < 12 {
                    return 2
                } else {
                    return 3
                }
            """),
            Example("""
                if i > 0 {
                    let a = 1
                    if a > 1 {
                        // comment
                    } else {
                        return 1
                    }
                    // comment
                } else {
                    return 3
                }
            """),
            Example("""
                if i > 0 {
                    if a > 1 {
                        return 1
                    }
                } else {
                    return 3
                }
            """),
            Example("""
                if i > 0 {
                    if a > 1 {
                        if a > 1 {
                            // comment
                        } else {
                            return 1
                        }
                    }
                } else {
                    return 3
                }
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("""
                ↓if i > 0 {
                    return 1
                    // comment
                } else {
                    return 2
                }
            """),
            Example("""
                ↓if i > 0 {
                    return 1
                } else ↓if i < 12 {
                    return 2
                } else if i > 18 {
                    return 3
                }
            """),
            Example("""
                ↓if i > 0 {
                    ↓if i < 12 {
                        return 5
                    } else {
                        ↓if i > 11 {
                            return 6
                        } else {
                            return 7
                        }
                    }
                } else ↓if i < 12 {
                    return 2
                } else ↓if i < 24 {
                    return 8
                } else {
                    return 3
                }
            """)
        ],
        corrections: [
            Example("""
                func f() -> Int {
                    ↓if i > 0 {
                        return 1
                        // comment
                    } else {
                        // another comment
                        return 2
                        // yet another comment
                    }
                }
            """): Example("""
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    }
                    // another comment
                    return 2
                    // yet another comment
                }
            """),
            Example("""
                func f() -> Int {
                    ↓if i > 0 {
                        return 1
                        // comment
                    } else ↓if i < 10 {
                        return 2
                    } else {
                        return 3
                    }
                }
            """): Example("""
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    }
                    if i < 10 {
                        return 2
                    }
                    return 3
                }
            """),
            Example("""
                func f() -> Int {

                    ↓if i > 0 {
                        return 1
                        // comment
                    } else if i < 10 {
                        // another comment
                        return 2
                    }
                }
            """): Example("""
                func f() -> Int {

                    if i > 0 {
                        return 1
                        // comment
                    }
                    if i < 10 {
                        // another comment
                        return 2
                    }
                }
            """),
            Example("""
                {
                    ↓if i > 0 {
                        return 1
                    } else {
                        return 2
                    }
                }()
            """): Example("""
                {
                    if i > 0 {
                        return 1
                    }
                    return 2
                }()
            """)
        ]
    )
}

private extension SuperfluousElseRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: IfExprSyntax) {
            if node.violatesRule {
                violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
            super.visit(restructure(list: node))
        }

        private func restructure(list: CodeBlockItemListSyntax, offset: Int = 0) -> CodeBlockItemListSyntax {
            var newStatements = CodeBlockItemListSyntax()
            var newOffset = 0
            for item in list {
                guard let ifStmt = item.item.as(ExpressionStmtSyntax.self)?.expression.as(IfExprSyntax.self),
                      !ifStmt.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                      ifStmt.violatesRule else {
                    newStatements.append(item)
                    continue
                }
                newOffset = ifStmt.body.rightBrace.endPositionBeforeTrailingTrivia.utf8Offset
                correctionPositions.append(ifStmt.ifKeyword.positionAfterSkippingLeadingTrivia.advanced(by: offset))
                let (newIfStm, removedItems) = modify(ifStmt: ifStmt)
                newStatements.append(
                    CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(ExpressionStmtSyntax(expression: newIfStm)))
                )
                newStatements.append(contentsOf: removedItems)
            }
            return newOffset > 0 ? restructure(list: newStatements, offset: newOffset) : newStatements
        }

        private func modify(ifStmt: IfExprSyntax) -> (newIfStmt: IfExprSyntax, removedItems: [CodeBlockItemSyntax]) {
            let ifStmtWithoutElse = removeElse(from: ifStmt)
            if case let .codeBlock(block) = ifStmt.elseBody {
                let indenter = CodeIndentingRewriter(style: .unindentSpaces(4))
                let unindentedBlock = indenter.rewrite(block).cast(CodeBlockSyntax.self)
                let items = unindentedBlock.statements.with(
                    \.trailingTrivia,
                    unindentedBlock.rightBrace.leadingTrivia.withTrailingEmptyLineRemoved
                )
                return (ifStmtWithoutElse, Array(items))
            }
            if case let .ifExpr(nestedIfStmt) = ifStmt.elseBody {
                let unindentedIfStmt = nestedIfStmt.with(
                    \.leadingTrivia,
                    Trivia(pieces: [.newlines(1)] + (ifStmt.leadingTrivia.indentation(isOnNewline: true) ?? Trivia()))
                )
                let item = CodeBlockItemSyntax(
                    item: CodeBlockItemSyntax.Item(ExpressionStmtSyntax(expression: unindentedIfStmt))
                )
                return (ifStmtWithoutElse, [item])
            }
            return (ifStmt, [])
        }

        private func removeElse(from ifStmt: IfExprSyntax) -> IfExprSyntax {
            ifStmt
                .with(\.body, ifStmt.body.with(\.rightBrace, ifStmt.body.rightBrace.with(\.trailingTrivia, Trivia())))
                .with(\.elseKeyword, nil)
                .with(\.elseBody, nil)
        }
    }
}

private extension IfExprSyntax {
    var violatesRule: Bool {
        if elseKeyword == nil {
            return false
        }
        let thenBodyReturns = lastStatementReturns(in: body)
        if thenBodyReturns, let parent = parent?.as(IfExprSyntax.self) {
            return parent.violatesRule
        }
        return thenBodyReturns
    }

    private var returnsInAllBranches: Bool {
        guard lastStatementReturns(in: body) else {
            return false
        }
        if case let .ifExpr(nestedIfStmt) = elseBody {
            return nestedIfStmt.returnsInAllBranches
        }
        if case let .codeBlock(block) = elseBody {
            return lastStatementReturns(in: block)
        }
        return false
    }

    private func lastStatementReturns(in block: CodeBlockSyntax) -> Bool {
        guard let lastItem = block.statements.last?.as(CodeBlockItemSyntax.self)?.item else {
            return false
        }
        if lastItem.is(ReturnStmtSyntax.self) {
            return true
        }
        if let exprStmt = lastItem.as(ExpressionStmtSyntax.self),
           let lastIfStmt = exprStmt.expression.as(IfExprSyntax.self) {
            return lastIfStmt.returnsInAllBranches
        }
        return false
    }
}
