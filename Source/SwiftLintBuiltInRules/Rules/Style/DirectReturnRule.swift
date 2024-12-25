import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct DirectReturnRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
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
                """),
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
                """),
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
                func f() -> UIView {
                    let view = instantiateView() as! UIView // swiftlint:disable:this force_cast
                    return view
                }
                """): Example("""
                    func f() -> UIView {
                        return instantiateView() as! UIView // swiftlint:disable:this force_cast
                    }
                    """),
            Example("""
                func f() -> UIView {
                    let view = instantiateView() as! UIView // swiftlint:disable:this force_cast
                    return view // return the view
                }
                """): Example("""
                    func f() -> UIView {
                        return instantiateView() as! UIView // swiftlint:disable:this force_cast // return the view
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
                    """),
        ]
    )
}

private extension DirectReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ statements: CodeBlockItemListSyntax) {
            if let (binding, _) = statements.violation {
                violations.append(binding.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ statements: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
            guard let (binding, returnStmt) = statements.violation,
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
                        asKeyword: .keyword(.as).with(\.leadingTrivia, .space).with(\.trailingTrivia, .space),
                        type: type.trimmed
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
                let leadingTrivia = varDecl.leadingTrivia.withoutTrailingIndentation +
                    returnStmt.leadingTrivia.withFirstEmptyLineRemoved
                let trailingTrivia = varDecl.trailingTrivia.withoutTrailingIndentation +
                    returnStmt.trailingTrivia

                newStmtList.append(
                    CodeBlockItemSyntax(
                        item: .stmt(
                            StmtSyntax(
                                returnStmt
                                    .with(\.expression, initExpression)
                                    .with(\.leadingTrivia, leadingTrivia)
                                    .with(\.trailingTrivia, trailingTrivia)
                            )
                        )
                    )
                )
            }
            return super.visit(CodeBlockItemListSyntax(newStmtList))
        }
    }
}

private extension CodeBlockItemListSyntax {
    var violation: (PatternBindingSyntax, ReturnStmtSyntax)? {
        guard count >= 2, let last = last?.item,
              let returnStmt = last.as(ReturnStmtSyntax.self),
              let identifier = returnStmt.expression?.as(DeclReferenceExprSyntax.self)?.baseName.text,
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
