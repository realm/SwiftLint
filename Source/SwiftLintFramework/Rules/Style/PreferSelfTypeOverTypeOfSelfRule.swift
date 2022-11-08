import SwiftSyntax

struct PreferSelfTypeOverTypeOfSelfRule: SwiftSyntaxCorrectableRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    static let description = RuleDescription(
        identifier: "prefer_self_type_over_type_of_self",
        name: "Prefer Self Type Over Type of Self",
        description: "Prefer `Self` over `type(of: self)` when accessing properties or calling methods.",
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
            """)
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
            """)
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
            """)
        ]
    )

    init() {}

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

private extension PreferSelfTypeOverTypeOfSelfRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if let function = node.base?.as(FunctionCallExprSyntax.self), function.hasViolation {
                violations.append(function.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: MemberAccessExprSyntax) -> ExprSyntax {
            guard let function = node.base?.as(FunctionCallExprSyntax.self),
                  function.hasViolation,
                  !function.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(function.positionAfterSkippingLeadingTrivia)

            let base: IdentifierExprSyntax = "Self"
            let baseWithTrivia = base
                .withLeadingTrivia(function.leadingTrivia ?? .zero)
                .withTrailingTrivia(function.trailingTrivia ?? .zero)
            return super.visit(node.withBase(ExprSyntax(baseWithTrivia)))
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasViolation: Bool {
        return isTypeOfSelfCall &&
            argumentList.map(\.label?.text) == ["of"] &&
            argumentList.first?.expression.as(IdentifierExprSyntax.self)?.identifier.tokenKind == .selfKeyword
    }

    var isTypeOfSelfCall: Bool {
        if let identifierExpr = calledExpression.as(IdentifierExprSyntax.self) {
            return identifierExpr.identifier.text == "type"
        } else if let memberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccessExpr.name.text == "type" &&
                memberAccessExpr.base?.as(IdentifierExprSyntax.self)?.identifier.text == "Swift"
        }
        return false
    }
}
