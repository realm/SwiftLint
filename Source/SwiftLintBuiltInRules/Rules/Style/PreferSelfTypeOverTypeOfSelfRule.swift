import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct PreferSelfTypeOverTypeOfSelfRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_self_type_over_type_of_self",
        name: "Prefer Self Type Over Type of Self",
        description: "Prefer `Self` over `type(of: self)` when accessing properties or calling methods",
        kind: .style,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            class Foo {
                func bar() {
                    Self.baz()
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(Self.baz)
                }
            }
            """),
            Example("""
            class A {
                func foo(param: B) {
                    type(of: param).bar()
                }
            }
            """),
            Example("""
            class A {
                func foo() {
                    print(type(of: self))
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            class Foo {
                func bar() {
                    ↓type(of: self).baz()
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓type(of: self).baz)
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓Swift.type(of: self).baz)
                }
            }
            """),
        ],
        corrections: [
            Example("""
            class Foo {
                func bar() {
                    ↓type(of: self).baz()
                }
            }
            """): Example("""
            class Foo {
                func bar() {
                    Self.baz()
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓type(of: self).baz)
                }
            }
            """): Example("""
            class Foo {
                func bar() {
                    print(Self.baz)
                }
            }
            """),
            Example("""
            class Foo {
                func bar() {
                    print(↓Swift.type(of: self).baz)
                }
            }
            """): Example("""
            class Foo {
                func bar() {
                    print(Self.baz)
                }
            }
            """),
        ]
    )
}

private extension PreferSelfTypeOverTypeOfSelfRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if let function = node.base?.as(FunctionCallExprSyntax.self), function.hasViolation {
                violations.append(function.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
            guard let function = node.base?.as(FunctionCallExprSyntax.self), function.hasViolation else {
                return super.visit(node)
            }

            correctionPositions.append(function.positionAfterSkippingLeadingTrivia)

            let base = DeclReferenceExprSyntax(baseName: "Self")
            let baseWithTrivia = base
                .with(\.leadingTrivia, function.leadingTrivia)
                .with(\.trailingTrivia, function.trailingTrivia)
            return super.visit(node.with(\.base, ExprSyntax(baseWithTrivia)))
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasViolation: Bool {
        isTypeOfSelfCall &&
        arguments.map(\.label?.text) == ["of"] &&
        arguments.first?.expression.as(DeclReferenceExprSyntax.self)?.baseName.tokenKind == .keyword(.self)
    }

    var isTypeOfSelfCall: Bool {
        if let identifierExpr = calledExpression.as(DeclReferenceExprSyntax.self) {
            return identifierExpr.baseName.text == "type"
        }
        if let memberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccessExpr.declName.baseName.text == "type" &&
            memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Swift"
        }
        return false
    }
}
