import SwiftSyntax

struct DirectReturnRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static var description = RuleDescription(
        identifier: "direct_return",
        name: "Direct Return",
        description: "Directly return the expression instead of assigning it to a variable first",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                func f() -> Int {
                    let b = 2
                    let a = 1
                    return b
                }
            """),
            Example("""
                struct S {
                    var a: Int {
                        var b = 1
                        b = 2
                        return b
                    }
                }
            """),
            Example("""
                func f() -> Int {
                    let b = 2
                    f()
                    return b
                }
            """),
            Example("""
                func f() -> Int {
                    { i in
                        let b = 2
                        return i
                    }(1)
                }
            """)
        ],
        triggeringExamples: [
            Example("""
                func f() -> Int {
                    let ↓b = 2
                    return b
                }
            """),
            Example("""
                struct S {
                    var a: Int {
                        var ↓b = 1
                        // comment
                        return b
                    }
                }
            """),
            Example("""
                func f() -> Bool {
                    let a = 1, ↓b = true
                    return b
                }
            """),
            Example("""
                func f() -> Int {
                    { _ in
                        let ↓b = 2
                        return b
                    }(1)
                }
            """),
            Example("""
                func f(i: Int) -> Int {
                    if i > 1 {
                        let ↓a = 2
                        return a
                    } else {
                        let ↓b = 2, a = 1
                        return b
                    }
                }
            """)
        ],
        corrections: [
            Example("""
                func f() -> Int {
                    let b = 2
                    return b
                }
            """): Example("""
                func f() -> Int {
                    return 2
                }
            """),
            Example("""
                struct S {
                    var a: Int {
                        var b = 2 > 1
                            ? f()
                            : 1_000
                        // comment
                        return b
                    }
                    func f() -> Int { 1 }
                }
            """): Example("""
                struct S {
                    var a: Int {
                        // comment
                        return 2 > 1
                            ? f()
                            : 1_000
                    }
                    func f() -> Int { 1 }
                }
            """),
            Example("""
                func f() -> Bool {
                    let a = 1, b = true
                    return b
                }
            """): Example("""
                func f() -> Bool {
                    let a = 1
                    return true
                }
            """),
            Example("""
                func f() -> Int {
                    { _ in
                        // A comment
                        let b = 2
                        // Another comment
                        return b
                    }(1)
                }
            """): Example("""
                func f() -> Int {
                    { _ in
                        // A comment
                        // Another comment
                        return 2
                    }(1)
                }
            """),
            Example("""
                func f() -> Bool {
                    let b  :  Bool  =  true
                    return b
                }
            """): Example("""
                func f() -> Bool {
                    return true as Bool
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

    override func visitPost(_ statements: CodeBlockItemListSyntax) {
        if let (binding, _) = statements.violation {
            violations.append(binding.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension CodeBlockItemListSyntax {
    var violation: (PatternBindingSyntax, ReturnStmtSyntax)? {
        guard count >= 2, let last = last?.item,
              let returnStmt = last.as(ReturnStmtSyntax.self),
              let identifier = returnStmt.expression?.as(IdentifierExprSyntax.self)?.identifier.text,
              let varDecl = dropLast().last?.item.as(VariableDeclSyntax.self) else {
            return nil
        }
        let binding = varDecl.bindings.first {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == identifier
        }
        if let binding {
            return (binding, returnStmt)
        }
        return nil
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

    override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        guard let (binding, returnStmt) = statements.violation,
              !binding.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
              let bindingList = binding.parent?.as(PatternBindingListSyntax.self),
              let varDecl = bindingList.parent?.as(VariableDeclSyntax.self),
              var initExpression = binding.initializer?.value else {
            return super.visit(statements)
        }
        correctionPositions.append(binding.positionAfterSkippingLeadingTrivia)
        var newStmtList = Array(statements.dropLast(2))
        let newBindingList = bindingList
            .filter { $0 != binding }
            .enumerated()
            .map { index, item in
                if index == bindingList.count - 2 {
                    return item.with(\.trailingComma, nil)
                }
                return item
            }
        if let type = binding.typeAnnotation?.type {
            initExpression = ExprSyntax(
                fromProtocol: AsExprSyntax(
                    expression: initExpression.trimmed,
                    asTok: .keyword(.as).with(\.leadingTrivia, .space).with(\.trailingTrivia, .space),
                    typeName: type.trimmed
                )
            )
        }
        if newBindingList.isNotEmpty {
            newStmtList.append(CodeBlockItemSyntax(
                item: .decl(DeclSyntax(varDecl.with(\.bindings, PatternBindingListSyntax(newBindingList))))
            ))
            newStmtList.append(CodeBlockItemSyntax(
                item: .stmt(StmtSyntax(returnStmt.with(\.expression, initExpression)))
            ))
        } else {
            let leadingTrivia = (varDecl.leadingTrivia?.withoutTrailingIndentation ?? .zero)
                              + (varDecl.trailingTrivia ?? .zero)
                              + (returnStmt.leadingTrivia?.withFirstEmptyLineRemoved ?? .zero)
            newStmtList.append(
                CodeBlockItemSyntax(
                    item: .stmt(
                        StmtSyntax(
                            returnStmt
                                .with(\.expression, initExpression)
                                .with(\.leadingTrivia, leadingTrivia)
                        )
                    )
                )
            )
        }
        return super.visit(CodeBlockItemListSyntax(newStmtList))
    }
}
