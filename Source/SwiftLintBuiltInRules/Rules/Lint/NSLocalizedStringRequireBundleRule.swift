import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct NSLocalizedStringRequireBundleRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "nslocalizedstring_require_bundle",
        name: "NSLocalizedString Require Bundle",
        description: "Calls to NSLocalizedString should specify the bundle which contains the strings file",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            NSLocalizedString("someKey", bundle: .main, comment: "test")
            """),
            Example("""
            NSLocalizedString("someKey", tableName: "a",
                              bundle: Bundle(for: A.self),
                              comment: "test")
            """),
            Example("""
            NSLocalizedString("someKey", tableName: "xyz",
                              bundle: someBundle, value: "test"
                              comment: "test")
            """),
            Example("""
            arbitraryFunctionCall("something")
            """),
        ],
        triggeringExamples: [
            Example("""
            ↓NSLocalizedString("someKey", comment: "test")
            """),
            Example("""
            ↓NSLocalizedString("someKey", tableName: "a", comment: "test")
            """),
            Example("""
            ↓NSLocalizedString("someKey", tableName: "xyz",
                              value: "test", comment: "test")
            """),
        ]
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
