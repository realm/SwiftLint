import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct DiscouragedVoidReturnRule: SwiftSyntaxCorrectableRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static var description = RuleDescription(
        identifier: "discouraged_void_return",
        name: "Discouraged Void Return",
        description: "Functions without a return type should not return an expression",
        kind: .style,
        nonTriggeringExamples: [
            Example("func f() -> Bool { return true }"),
            Example("func f() -> Bool { true }"),
            Example("func f() -> Void { g() }"),
            Example("func f() -> () { g() }"),
            Example("func f() { g() }"),
            Example("func f() { { return g() }() }"),
            Example("""
            func f() {
                func g() -> Int {
                    return 1
                }
            }
            """),
            Example("init?() { return nil }"),
            Example("""
            func f() {
                var i: Int { return 1 }
            }
            """)
        ],
        triggeringExamples: [
            Example("func f() -> Void { ↓return g() }"),
            Example("func f() -> () { ↓return g() }"),
            Example("func f() { ↓return g() }"),
            Example("""
            func f(b: Bool) {
                if b {
                    ↓return g()
                }
            }
            """)
        ],
        corrections: [
            Example("""
            func f() -> Void {
                ↓return g()
                // some comment
            }
            """): Example("""
                func f() -> Void {
                    g()
                    return
                    // some comment
                }
                """),
            Example("""
            func f(b: Bool) {
                if b {
                    // some comment
                    ↓return g()
                }
            }
            """): Example("""
                func f(b: Bool) {
                    if b {
                        // some comment
                        g()
                        return
                    }
                }
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

private extension DiscouragedVoidReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var returnsVoidScope = Stack<Bool>()

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visit(_ node: AccessorBlockSyntax) -> SyntaxVisitorContinueKind {
            returnsVoidScope.push(false)
            return .visitChildren
        }

        override func visitPost(_ node: AccessorBlockSyntax) {
            returnsVoidScope.pop()
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            returnsVoidScope.push(false)
            return .visitChildren
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            returnsVoidScope.pop()
        }

        override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
            returnsVoidScope.push(false)
            return .visitChildren
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            returnsVoidScope.pop()
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let type = node.signature.returnClause?.type {
                if type.as(TupleTypeSyntax.self)?.elements.isEmpty == true ||
                   type.as(IdentifierTypeSyntax.self)?.name.text == "Void" {
                    returnsVoidScope.push(true)
                } else {
                    returnsVoidScope.push(false)
                }
            } else {
                returnsVoidScope.push(true)
            }
            return .visitChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            returnsVoidScope.pop()
        }

        override func visitPost(_ node: ReturnStmtSyntax) {
            if returnsVoidScope.peek() == true, node.expression != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let violationPositions: [AbsolutePosition]

        init(configuration: ConfigurationType,
             file: SwiftLintFile,
             disabledRegions: [SourceRange]) {
            self.violationPositions = Visitor(configuration: configuration, file: file).walk(file: file) {
                $0.violations.map(\.position)
            }
            super.init(locationConverter: file.locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
            guard let returnStmt = statements.last?.item.as(ReturnStmtSyntax.self),
                  let expr = returnStmt.expression,
                  violationPositions.contains(returnStmt.positionAfterSkippingLeadingTrivia) else {
                return super.visit(statements)
            }
            correctionPositions.append(returnStmt.positionAfterSkippingLeadingTrivia)
            let newStmtList = Array(statements.dropLast()) + [
                CodeBlockItemSyntax(item: .expr(expr))
                    .with(\.leadingTrivia, returnStmt.leadingTrivia),
                CodeBlockItemSyntax(item: .stmt(StmtSyntax(
                    returnStmt
                        .with(\.expression, nil)
                        .with(
                            \.leadingTrivia,
                            .newline + (returnStmt.leadingTrivia.indentation(isOnNewline: false) ?? []))
                        .with(\.trailingTrivia, returnStmt.trailingTrivia)
                )))
            ]
            return super.visit(CodeBlockItemListSyntax(newStmtList))
        }
    }
}
