import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct RedundantVoidReturnRule: Rule {
    var configuration = RedundantVoidReturnConfiguration()

    static let description = RuleDescription(
        identifier: "redundant_void_return",
        name: "Redundant Void Return",
        description: "Returning Void in a function declaration is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("func foo() {}"),
            Example("func foo() -> Int {}"),
            Example("func foo() -> Int -> Void {}"),
            Example("func foo() -> VoidResponse"),
            Example("let foo: (Int) -> Void"),
            Example("func foo() -> Int -> () {}"),
            Example("let foo: (Int) -> ()"),
            Example("func foo() -> ()?"),
            Example("func foo() -> ()!"),
            Example("func foo() -> Void?"),
            Example("func foo() -> Void!"),
            Example("""
            struct A {
                subscript(key: String) {
                    print(key)
                }
            }
            """),
            Example("""
            doSomething { arg -> Void in
                print(arg)
            }
            """, configuration: ["include_closures": false]),
            Example("""
            func takesClosure(_ closure: () -> Void) {}

            func returnsInt() -> Int { 42 }

            let testClosure = { () -> Void in returnsInt() }

            takesClosure(testClosure)
            """),
        ],
        triggeringExamples: [
            Example("func foo()↓ -> Void {}"),
            Example("""
            protocol Foo {
              func foo()↓ -> Void
            }
            """),
            Example("func foo()↓ -> () {}"),
            Example("func foo()↓ -> ( ) {}"),
            Example("""
            protocol Foo {
              func foo()↓ -> ()
            }
            """),
            Example("""
            doSomething { arg↓ -> () in
                print(arg)
            }
            """),
            Example("""
            doSomething { arg↓ -> Void in
                print(arg)
            }
            """),
        ],
        corrections: [
            Example("func foo()↓ -> Void {}"): Example("func foo() {}"),
            Example("protocol Foo {\n func foo()↓ -> Void\n}"): Example("protocol Foo {\n func foo()\n}"),
            Example("func foo()↓ -> () {}"): Example("func foo() {}"),
            Example("protocol Foo {\n func foo()↓ -> ()\n}"): Example("protocol Foo {\n func foo()\n}"),
            Example("protocol Foo {\n    #if true\n    func foo()↓ -> Void\n    #endif\n}"):
                Example("protocol Foo {\n    #if true\n    func foo()\n    #endif\n}"),
        ]
    )
}

private extension RedundantVoidReturnRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ReturnClauseSyntax) {
            if !configuration.includeClosures, node.parent?.is(ClosureSignatureSyntax.self) == true {
                return
            }

            if node.shouldSkipClosureRedundantVoidRemoval {
                return
            }

            if node.containsRedundantVoidViolation,
               let tokenBeforeOutput = node.previousToken(viewMode: .sourceAccurate) {
                violations.append(tokenBeforeOutput.endPositionBeforeTrailingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
            // Closures may use an explicit `Void` return to keep a `() -> Void` type when the body
            // returns a non-Void value (e.g. `{ () -> Void in returnsInt() }`). Removing the
            // annotation changes the inferred closure type and breaks call sites.
            super.visit(node)
        }

        override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
            guard let output = node.returnClause,
                  output.previousToken(viewMode: .sourceAccurate) != nil,
                  output.containsRedundantVoidViolation
            else {
                return super.visit(node)
            }
            numberOfCorrections += 1
            return super.visit(node.with(\.returnClause, nil).removingTrailingSpaceIfNeeded())
        }
    }
}

private extension ReturnClauseSyntax {
    var shouldSkipClosureRedundantVoidRemoval: Bool {
        guard parent?.is(ClosureSignatureSyntax.self) == true,
              let closure = Syntax(self).enclosingClosure() else {
            return false
        }

        if closure.statements.contains(where: \.containsReturnStatement) {
            return true
        }

        guard let expression = closure.singleExpressionBody else {
            return false
        }

        if let call = expression.as(FunctionCallExprSyntax.self) {
            return !call.isKnownVoidProducingCall
        }

        return true
    }

    var containsRedundantVoidViolation: Bool {
        if parent?.is(FunctionTypeSyntax.self) == true {
            return false
        }
        if let simpleReturnType = type.as(IdentifierTypeSyntax.self) {
            return simpleReturnType.typeName == "Void"
        }
        if let tupleReturnType = type.as(TupleTypeSyntax.self) {
            return tupleReturnType.elements.isEmpty
        }
        return false
    }
}

private extension CodeBlockItemSyntax {
    var containsReturnStatement: Bool {
        item.is(ReturnStmtSyntax.self)
    }
}

private extension ClosureExprSyntax {
    var singleExpressionBody: ExprSyntax? {
        guard statements.count == 1,
              let statement = statements.onlyElement,
              case let .expr(expression) = statement.item else {
            return nil
        }

        return expression
    }
}

private extension FunctionCallExprSyntax {
    var isKnownVoidProducingCall: Bool {
        let name = calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text
            ?? calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text

        guard let name else {
            return false
        }

        return Self.knownVoidProducingFunctions.contains(name)
    }

    private static let knownVoidProducingFunctions: Set<String> = [
        "print",
        "debugPrint",
        "dump",
        "fatalError",
        "preconditionFailure",
        "assertionFailure",
        "withExtendedLifetime",
    ]
}

private extension Syntax {
    func enclosingClosure() -> ClosureExprSyntax? {
        var syntax: Syntax? = self
        while let current = syntax {
            if let closure = current.as(ClosureExprSyntax.self) {
                return closure
            }
            syntax = current.parent
        }
        return nil
    }
}

private extension SyntaxProtocol {
    /// `withOutput(nil)` adds a `.spaces(1)` trailing trivia, but we don't always want it.
    func removingTrailingSpaceIfNeeded() -> Self {
        guard
            let nextToken = nextToken(viewMode: .sourceAccurate),
            nextToken.leadingTrivia.containsNewlines()
        else {
            return self
        }

        return with(
            \.trailingTrivia,
            Trivia(pieces: trailingTrivia.dropFirst())
        )
    }
}
