import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PrefixedTopLevelConstantRule: Rule {
    var configuration = PrefixedTopLevelConstantConfiguration()

    static let description = RuleDescription(
        identifier: "prefixed_toplevel_constant",
        name: "Prefixed Top-Level Constant",
        description: "Top-level constants should be prefixed by `k`",
        kind: .style,
        nonTriggeringExamples: #examples([
            "private let kFoo = 20.0",
            "public let kFoo = false",
            "internal let kFoo = \"Foo\"",
            "let kFoo = true",
            "let Foo = true".configuration(["only_private": true]),
            """
            struct Foo {
                let bar = 20.0
            }
            """,
            "private var foo = 20.0",
            "public var foo = false",
            "internal var foo = \"Foo\"",
            "var foo = true",
            "var foo = true, bar = true",
            "var foo = true, let kFoo = true",
            """
            let
                kFoo = true
            """,
            """
            var foo: Int {
                return a + b
            }
            """,
            """
            let kFoo = {
                return a + b
            }()
            """,
            """
            var foo: String {
                let bar = ""
                return bar
            }
            """,
            """
            if condition() {
                let result = somethingElse()
                print(result)
                exit()
            }
            """,
            #"""
            [1, 2, 3, 1000, 4000].forEach { number in
                let isSmall = number < 10
                if isSmall {
                    print("\(number) is a small number")
                }
            }
            """#,
        ]),
        triggeringExamples: #examples([
            "private let ↓Foo = 20.0",
            "public let ↓Foo = false",
            "internal let ↓Foo = \"Foo\"",
            "let ↓Foo = true",
            "let ↓foo = 2, ↓bar = true",
            """
            let
                ↓foo = true
            """,
            """
            let ↓foo = {
                return a + b
            }()
            """,
        ])
    )
}

private extension PrefixedTopLevelConstantRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private let topLevelPrefix = "k"

        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: VariableDeclSyntax) {
            guard node.bindingSpecifier.tokenKind == .keyword(.let) else {
                return
            }

            if configuration.onlyPrivateMembers, !node.modifiers.containsPrivateOrFileprivate() {
                return
            }

            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
                      !pattern.identifier.text.hasPrefix(topLevelPrefix) else {
                    continue
                }

                violations.append(binding.pattern.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}
