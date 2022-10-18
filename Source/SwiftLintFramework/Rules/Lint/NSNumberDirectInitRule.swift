import SwiftSyntax

// this rule exists due to a compiler bug: https://github.com/apple/swift/issues/51036
public struct NSNumberDirectInitRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "ns_number_direct_init",
        name: "NSNumber Direct Init",
        description: "Passing `NSNumber.init` or `NSDecimalNumber.init` as a function reference is dangerous " +
                     "as it can cause the wrong initializer to be used, causing crashes. Use `.init(value:)` instead.",
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NSNumberDirectInitRule {
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
