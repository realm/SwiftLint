import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PrefixedTopLevelConstantRule: Rule {
    var configuration = PrefixedTopLevelConstantConfiguration()

    static let description = RuleDescription(
        identifier: "prefixed_toplevel_constant",
        name: "Prefixed Top-Level Constant",
        description: "Top-level constants should be prefixed by `k`",
        kind: .style,
        nonTriggeringExamples: [
            Example("private let kFoo = 20.0"),
            Example("public let kFoo = false"),
            Example("internal let kFoo = \"Foo\""),
            Example("let kFoo = true"),
            Example("let Foo = true", configuration: ["only_private": true]),
            Example("""
            struct Foo {
                let bar = 20.0
            }
            """),
            Example("private var foo = 20.0"),
            Example("public var foo = false"),
            Example("internal var foo = \"Foo\""),
            Example("var foo = true"),
            Example("var foo = true, bar = true"),
            Example("var foo = true, let kFoo = true"),
            Example("""
            let
                kFoo = true
            """),
            Example("""
            var foo: Int {
                return a + b
            }
            """),
            Example("""
            let kFoo = {
                return a + b
            }()
            """),
            Example("""
            var foo: String {
                let bar = ""
                return bar
            }
            """),
            Example("""
            if condition() {
                let result = somethingElse()
                print(result)
                exit()
            }
            """),
            Example(#"""
            [1, 2, 3, 1000, 4000].forEach { number in
                let isSmall = number < 10
                if isSmall {
                    print("\(number) is a small number")
                }
            }
            """#),
        ],
        triggeringExamples: [
            Example("private let ↓Foo = 20.0"),
            Example("public let ↓Foo = false"),
            Example("internal let ↓Foo = \"Foo\""),
            Example("let ↓Foo = true"),
            Example("let ↓foo = 2, ↓bar = true"),
            Example("""
            let
                ↓foo = true
            """),
            Example("""
            let ↓foo = {
                return a + b
            }()
            """),
        ]
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
