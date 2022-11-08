import SwiftSyntax

struct NSLocalizedStringRequireBundleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "nslocalizedstring_require_bundle",
        name: "NSLocalizedString Require Bundle",
        description: "Calls to NSLocalizedString should specify the bundle which contains the strings file.",
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
            """)
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
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NSLocalizedStringRequireBundleRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               identifierExpr.identifier.tokenKind == .identifier("NSLocalizedString"),
               !node.argumentList.containsArgument(named: "bundle") {
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
