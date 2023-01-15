import SwiftSyntax

struct SuperfluousElseRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "superfluous_else",
        name: "Superfluous Else Block",
        description: "Else-blocks should be avoided when the previous if-blocks all left the current scope",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                if i > 0 {
                    // comment
                } else if i < 12 {
                    // comment
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
            """)
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
                        return 2
                    }
                }
            """): Example("""
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    }
                    return 2
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
                        // comment
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
                    // comment
                    return 3
                }
            """),
            Example("""
                func f() -> Int {
                    ↓if i > 0 {
                        return 1
                        // comment
                    } else if i < 10 {
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
                        return 2
                    }
                }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
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
        elseKeyword != nil && lastStatementReturns(in: body)
    }

    private func lastStatementReturns(in block: CodeBlockSyntax) -> Bool {
        guard let lastItem = block.statements.last?.as(CodeBlockItemSyntax.self)?.item else {
            return false
        }
        if lastItem.is(ReturnStmtSyntax.self) {
            return true
        }
        if let last = lastItem.as(IfStmtSyntax.self) {
            return lastStatementReturns(in: last.body)
        }
        return false
    }
}

private class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
        var newStatements = [CodeBlockItemSyntax]()
        var ifStmtSeen = false
        for item in node.statements {
            guard let ifStmt = item.item.as(IfStmtSyntax.self), ifStmt.violatesRule,
                  !ifStmt.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                newStatements.append(item)
                continue
            }
            ifStmtSeen = true
            correctionPositions.append(ifStmt.ifKeyword.positionAfterSkippingLeadingTrivia)
            let (newIfStm, removedItems) = modify(ifStmt: ifStmt)
            newStatements.append(CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(newIfStm)))
            newStatements.append(contentsOf: removedItems)
        }
        if ifStmtSeen {
            return visit(node.withStatements(CodeBlockItemListSyntax(newStatements)))
        }
        return super.visit(node.withStatements(CodeBlockItemListSyntax(newStatements)))
    }

    private func modify(ifStmt: IfStmtSyntax) -> (newIfStmt: IfStmtSyntax, removedItems: [CodeBlockItemSyntax]) {
        if case let .codeBlock(block) = ifStmt.elseBody {
            return (
                removeElse(from: ifStmt, withTrailingTrivia: block.leftBrace.trailingTrivia),
                block.statements.map { stmt in
                    let comments = stmt.leadingTrivia.dropFirstNoneComments
                    return stmt.withLeadingTrivia((ifStmt.leadingTrivia ?? .zero) + comments)
                }
            )
        }
        if case let .ifStmt(nestedIfStmt) = ifStmt.elseBody {
            let removedItems = [
                CodeBlockItemSyntax(
                    item: CodeBlockItemSyntax.Item(nestedIfStmt.withLeadingTrivia(ifStmt.leadingTrivia ?? .zero))
                )
            ]
            return (
                removeElse(from: ifStmt, withTrailingTrivia: nestedIfStmt.body.leftBrace.trailingTrivia.dropFirstNoneComments),
                removedItems
            )
        }
        return (ifStmt, [])
    }

    private func removeElse(from ifStmt: IfStmtSyntax, withTrailingTrivia trivia: Trivia) -> IfStmtSyntax {
        ifStmt
            .withBody(ifStmt.body.withRightBrace(ifStmt.body.rightBrace.withTrailingTrivia(trivia)))
            .withElseKeyword(nil)
            .withElseBody(nil)
    }
}

private extension Trivia? {
    var dropFirstNoneComments: Trivia {
        if let self {
            return Trivia(pieces: Array(self.drop(while: \.isOtherThanComment)))
        }
        return .zero
    }
}
