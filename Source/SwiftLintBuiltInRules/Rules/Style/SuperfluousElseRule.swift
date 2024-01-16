import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct SuperfluousElseRule: SwiftSyntaxCorrectableRule, OptInRule {
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
                if i > 0 {
                    return 1
                    // comment
                } ↓else {
                    return 2
                }
            """),
            Example("""
                if i > 0 {
                    return 1
                } ↓else if i < 12 {
                    return 2
                } ↓else if i > 18 {
                    return 3
                }
            """),
            Example("""
                if i > 0 {
                    if i < 12 {
                        return 5
                    } ↓else {
                        if i > 11 {
                            return 6
                        } ↓else {
                            return 7
                        }
                    }
                } ↓else if i < 12 {
                    return 2
                } ↓else if i < 24 {
                    return 8
                } ↓else {
                    return 3
                }
            """)
        ],
        corrections: [
            Example("""
                func f() -> Int {
                    if i > 0 {
                        return 1
                        // comment
                    } ↓else {
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
                    if i > 0 {
                        return 1
                        // comment
                    } ↓else if i < 10 {
                        return 2
                    } ↓else {
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

                    if i > 0 {
                        return 1
                        // comment
                    } ↓else if i < 10 {
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
                    if i > 0 {
                        return 1
                    } ↓else {
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

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            configuration: configuration,
            file: file,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension SuperfluousElseRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: IfExprSyntax) {
            if let elseKeyword = node.superfluousElse {
                violations.append(elseKeyword.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        init(configuration: ConfigurationType,
             file: SwiftLintFile,
             disabledRegions: [SourceRange]) {
            super.init(locationConverter: file.locationConverter, disabledRegions: disabledRegions)
            let correctionPositions = Visitor(configuration: configuration, file: file).walk(file: file) {
                $0.violations.map(\.position)
            }.filter { !$0.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) }
            self.correctionPositions.append(contentsOf: correctionPositions)
        }

        override func visitAny(_ node: Syntax) -> Syntax? {
            correctionPositions.isEmpty ? node : nil // Avoid skipping all `if` expressions in a code block.
        }

        override func visit(_ list: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
            var newStatements = CodeBlockItemListSyntax()
            var ifExprRewritten = false
            for item in list {
                guard let ifExpr = item.item.as(ExpressionStmtSyntax.self)?.expression.as(IfExprSyntax.self),
                      let elseKeyword = ifExpr.superfluousElse,
                      !elseKeyword.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                    newStatements.append(item)
                    continue
                }
                ifExprRewritten = true
                let (newIfStm, removedItems) = modify(ifExpr: ifExpr)
                newStatements.append(
                    CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(ExpressionStmtSyntax(expression: newIfStm)))
                )
                newStatements.append(contentsOf: removedItems)
            }
            return ifExprRewritten ? visit(newStatements) : super.visit(newStatements)
        }

        private func modify(ifExpr: IfExprSyntax) -> (newIfExpr: IfExprSyntax, removedItems: [CodeBlockItemSyntax]) {
            let ifExprWithoutElse = removeElse(from: ifExpr)
            if case let .codeBlock(block) = ifExpr.elseBody {
                let indenter = CodeIndentingRewriter(style: .unindentSpaces(4))
                let unindentedBlock = indenter.rewrite(block).cast(CodeBlockSyntax.self)
                let items = unindentedBlock.statements.with(
                    \.trailingTrivia,
                    unindentedBlock.rightBrace.leadingTrivia.withTrailingEmptyLineRemoved
                )
                return (ifExprWithoutElse, Array(items))
            }
            if case let .ifExpr(nestedIfExpr) = ifExpr.elseBody {
                let unindentedIfExpr = nestedIfExpr.with(
                    \.leadingTrivia,
                    Trivia(pieces: [.newlines(1)] + (ifExpr.leadingTrivia.indentation(isOnNewline: true) ?? Trivia()))
                )
                let item = CodeBlockItemSyntax(
                    item: CodeBlockItemSyntax.Item(ExpressionStmtSyntax(expression: unindentedIfExpr))
                )
                return (ifExprWithoutElse, [item])
            }
            return (ifExpr, [])
        }

        private func removeElse(from ifExpr: IfExprSyntax) -> IfExprSyntax {
            ifExpr
                .with(\.body, ifExpr.body.with(\.rightBrace, ifExpr.body.rightBrace.with(\.trailingTrivia, Trivia())))
                .with(\.elseKeyword, nil)
                .with(\.elseBody, nil)
        }
    }
}

private extension IfExprSyntax {
    var superfluousElse: TokenSyntax? {
        if elseKeyword == nil {
            return nil
        }
        if !lastStatementReturns(in: body) {
            return nil
        }
        if let parent = parent?.as(IfExprSyntax.self) {
            return parent.superfluousElse != nil ? elseKeyword : nil
        }
        return elseKeyword
    }

    private var returnsInAllBranches: Bool {
        guard lastStatementReturns(in: body) else {
            return false
        }
        if case let .ifExpr(nestedIfExpr) = elseBody {
            return nestedIfExpr.returnsInAllBranches
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
           let lastIfExpr = exprStmt.expression.as(IfExprSyntax.self) {
            return lastIfExpr.returnsInAllBranches
        }
        return false
    }
}
