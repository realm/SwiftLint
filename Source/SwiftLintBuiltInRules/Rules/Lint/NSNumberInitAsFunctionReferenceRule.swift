import SwiftSyntax

// this rule exists due to a compiler bug: https://github.com/apple/swift/issues/51036
@SwiftSyntaxRule
struct NSNumberInitAsFunctionReferenceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "ns_number_init_as_function_reference",
        name: "NSNumber Init as Function Reference",
        description: "Passing `NSNumber.init` or `NSDecimalNumber.init` as a function reference is dangerous " +
                     "as it can cause the wrong initializer to be used, causing crashes; use `.init(value:)` instead",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "[0, 0.2].map(NSNumber.init(value:))",
            "let value = NSNumber.init(value: 0.0)",
            "[0, 0.2].map { NSNumber(value: $0) }",
            "[0, 0.2].map(NSDecimalNumber.init(value:))",
            "[0, 0.2].map { NSDecimalNumber(value: $0) }",
        ]),
        triggeringExamples: #examples([
            "[0, 0.2].map(↓NSNumber.init)",
            "[0, 0.2].map(↓NSDecimalNumber.init)",
        ])
    )
}

private extension NSNumberInitAsFunctionReferenceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard node.declName.argumentNames.isEmptyOrNil,
                  node.declName.baseName.text == "init",
                  node.parent?.as(FunctionCallExprSyntax.self) == nil,
                  let baseText = node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text,
                  baseText == "NSNumber" || baseText == "NSDecimalNumber" else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension DeclNameArgumentsSyntax? {
    var isEmptyOrNil: Bool {
        self?.arguments.isEmpty ?? true
    }
}
