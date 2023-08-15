import SwiftSyntax

struct UIImageIncludesBundleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "uiimage_requires_bundle",
        name: "UIImage Requires Bundle",
        description: "`UIImage(named:) must specify a bundle via the `in:` parameter",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            UIImage(named: "image", in: Bundle.main)
            """),
            Example("""
            UIImageView(image: UIImage(named: "image", in: Bundle(for A.self)))
            """),
            Example("""
            UIImage(named: "image", in: Bundle(for A.self))
            """),
            Example("""
            UIImage(named: "image", in: Bundle.main, compatibleWith: aCollection)
            """),
            Example("""
            UIImage(named: "image", in: Bundle.main, with: aConfiguration)
            """),
            Example("""
            UIImage(systemName: "systemImage")
            """),
            Example("""
            UIImage(systemName: "systemImage", compatibleWith: aCollection)
            """),
            Example("""
            UIImage(systemName: "systemImage", withConfiguration: aConfiguration)
            """),
            Example("""
            UIImage(systemName: "systemImage", variableValue: 0.5)
            """),
            Example("""
            UIImage(systemName: "systemImage", variableValue: 0.5, configuration: aConfiguration)
            """),
            Example("""
            UIImage(
                named: "image",
                in: Bundle.main
            )
            """),
            Example("""
            arbitraryFunctionCall("something")
            """),
            Example("""
            UIImageView(image: UIImage(named: "hashtag", in: Bundle.main))
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓UIImage(named: "image")
            """),
            Example("""
            UIImageView(image: ↓UIImage(named: "image"))
            """),
            Example("""
            ↓UIImage(named: "image", compatibleWith: aCollection)
            """),
            Example("""
            ↓UIImage(named: "image", with: aConfiguration)
            """),
            Example("""
            ↓UIImage(
                named: "image"
            )
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension UIImageIncludesBundleRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               identifierExpr.identifier.tokenKind == .identifier("UIImage"),
               node.argumentList.containsArgument(named: "named"),
               !node.argumentList.containsArgument(named: "in") {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension TupleExprElementListSyntax {
    func containsArgument(named name: String) -> Bool {
        contains { arg in
            arg.label?.tokenKind == .identifier(name)
        }
    }
}
