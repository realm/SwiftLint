import SwiftSyntax

struct DisallowTopLevelVariablesRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration: SeverityConfiguration = .init(.warning)

    static let description: RuleDescription = .init(
        identifier: "disallow_top_level_variables",
        name: "Disallow Top-Level Variables",
        description: "Top-Level variables and constants should be avoided",
        kind: .style,
        nonTriggeringExamples: [
            Example(
                """
                struct A {
                    public var a: Int = 12
                }
                """
            )
        ],
        triggeringExamples: [
            Example("var ↓a: Int = 11"),
            Example("let ↓a: Int = 11"),
            Example("private var ↓a: Int = 11"),
            Example("public var ↓a: String?"),
            Example("public var ↓b: Int { return 42 }")
        ])

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor()
    }
}

private extension DisallowTopLevelVariablesRule {
    final class Visitor: ViolationsSyntaxVisitor {
        init() {
            super.init(viewMode: .sourceAccurate)
        }

        override var skippableDeclarations: [DeclSyntaxProtocol.Type] { .all }

        override func visitPost(_ node: VariableDeclSyntax) {
            let kind = node.bindingKeyword.tokenKind
            guard kind == .keyword(.let) || kind == .keyword(.var) else {
                return
            }

            for binding in node.bindings {
                guard let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
                    continue
                }

                violations.append(pattern.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            .skipChildren
        }
    }
}
