import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NSLocalizedStringRequireBundleRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "nslocalizedstring_require_bundle",
        name: "NSLocalizedString Require Bundle",
        description: "Calls to NSLocalizedString should specify the bundle which contains the strings file",
        kind: .lint,
        nonTriggeringExamples: #examples([
            """
            NSLocalizedString("someKey", bundle: .main, comment: "test")
            """,
            """
            NSLocalizedString("someKey", tableName: "a",
                              bundle: Bundle(for: A.self),
                              comment: "test")
            """,
            """
            NSLocalizedString("someKey", tableName: "xyz",
                              bundle: someBundle, value: "test"
                              comment: "test")
            """,
            """
            arbitraryFunctionCall("something")
            """,
        ]),
        triggeringExamples: #examples([
            """
            ↓NSLocalizedString("someKey", comment: "test")
            """,
            """
            ↓NSLocalizedString("someKey", tableName: "a", comment: "test")
            """,
            """
            ↓NSLocalizedString("someKey", tableName: "xyz",
                              value: "test", comment: "test")
            """,
        ])
    )
}

private extension NSLocalizedStringRequireBundleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(DeclReferenceExprSyntax.self),
               identifierExpr.baseName.tokenKind == .identifier("NSLocalizedString"),
               !node.arguments.containsArgument(named: "bundle") {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension LabeledExprListSyntax {
    func containsArgument(named name: String) -> Bool {
        contains { arg in
            arg.label?.tokenKind == .identifier(name)
        }
    }
}
