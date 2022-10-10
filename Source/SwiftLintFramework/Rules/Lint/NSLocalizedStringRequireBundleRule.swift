import SwiftSyntax

public struct NSLocalizedStringRequireBundleRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NSLocalizedStringRequireBundleRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let identifierExpr = node.calledExpression.as(IdentifierExprSyntax.self),
               identifierExpr.identifier.tokenKind == .identifier("NSLocalizedString"),
               !node.argumentList.containsArgument(named: "bundle") {
                violationPositions.append(node.positionAfterSkippingLeadingTrivia)
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
