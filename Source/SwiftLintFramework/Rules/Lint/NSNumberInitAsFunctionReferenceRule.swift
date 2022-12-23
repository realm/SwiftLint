import SwiftSyntax

// this rule exists due to a compiler bug: https://github.com/apple/swift/issues/51036
struct NSNumberInitAsFunctionReferenceRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "ns_number_init_as_function_reference",
        name: "NSNumber Init as Function Reference",
        description: "Passing `NSNumber.init` or `NSDecimalNumber.init` as a function reference is dangerous " +
                     "as it can cause the wrong initializer to be used, causing crashes; use `.init(value:)` instead",
        kind: .lint,
        nonTriggeringExamples: [
            Example("[0, 0.2].map(NSNumber.init(value:))"),
            Example("[0, 0.2].map { NSNumber(value: $0) }"),
            Example("[0, 0.2].map(NSDecimalNumber.init(value:))"),
            Example("[0, 0.2].map { NSDecimalNumber(value: $0) }")
        ],
        triggeringExamples: [
            Example("[0, 0.2].map(↓NSNumber.init)"),
            Example("[0, 0.2].map(↓NSDecimalNumber.init)")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NSNumberInitAsFunctionReferenceRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            guard node.declNameArguments.isEmptyOrNil,
                  node.name.text == "init",
                  let baseText = node.base?.as(IdentifierExprSyntax.self)?.identifier.text,
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
