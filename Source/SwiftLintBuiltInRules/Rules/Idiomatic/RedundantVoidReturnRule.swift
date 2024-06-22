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
            if !configuration.includeClosures && node.parent?.is(ClosureSignatureSyntax.self) == true {
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
            guard configuration.includeClosures,
                  let output = node.returnClause,
                  let tokenBeforeOutput = output.previousToken(viewMode: .sourceAccurate),
                  output.containsRedundantVoidViolation
            else {
                return super.visit(node)
            }

            correctionPositions.append(tokenBeforeOutput.endPositionBeforeTrailingTrivia)
            return super.visit(node.with(\.returnClause, nil).removingTrailingSpaceIfNeeded())
        }

        override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
            guard let output = node.returnClause,
                  let tokenBeforeOutput = output.previousToken(viewMode: .sourceAccurate),
                  output.containsRedundantVoidViolation
            else {
                return super.visit(node)
            }

            correctionPositions.append(tokenBeforeOutput.endPositionBeforeTrailingTrivia)
            return super.visit(node.with(\.returnClause, nil).removingTrailingSpaceIfNeeded())
        }
    }
}

private extension ReturnClauseSyntax {
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
