import SwiftSyntax

struct SuperfluousElseRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
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
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private class Visitor: ViolationsSyntaxVisitor {
    override var skippableDeclarations: [DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

    override func visitPost(_ node: IfStmtSyntax) {
        if node.violatesRule {
            violations.append(node.ifKeyword.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension IfStmtSyntax {
    var violatesRule: Bool {
        if elseKeyword == nil {
            return false
        }
        let thenBodyReturns = lastStatementReturns(in: body)
        if thenBodyReturns, let parent = parent?.as(IfStmtSyntax.self) {
            return parent.violatesRule
        }
        return thenBodyReturns
    }

    private var returnsInAllBranches: Bool {
        guard lastStatementReturns(in: body) else {
            return false
        }
        if case let .ifStmt(nestedIfStmt) = elseBody {
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
        if let last = lastItem.as(IfStmtSyntax.self) {
            return last.returnsInAllBranches
        }
        return false
    }
}
