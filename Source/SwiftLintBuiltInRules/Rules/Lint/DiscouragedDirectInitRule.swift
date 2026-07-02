import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct DiscouragedDirectInitRule: Rule {
    var configuration = DiscouragedDirectInitConfiguration()

    static let description = RuleDescription(
        identifier: "discouraged_direct_init",
        name: "Discouraged Direct Initialization",
        description: "Discouraged direct initialization of types that can be harmful",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "let foo = UIDevice.current",
            "let foo = Bundle.main",
            "let foo = Bundle(path: \"bar\")",
            "let foo = Bundle(identifier: \"bar\")",
            "let foo = Bundle.init(path: \"bar\")",
            "let foo = Bundle.init(identifier: \"bar\")",
            "let foo = NSError(domain: \"bar\", code: 0)",
            "let foo = NSError.init(domain: \"bar\", code: 0)",
            "func testNSError()",
        ]),
        triggeringExamples: #examples([
            "↓UIDevice()",
            "↓Bundle()",
            "let foo = ↓UIDevice()",
            "let foo = ↓Bundle()",
            "let foo = ↓NSError()",
            "let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice(), error: ↓NSError())",
            "↓UIDevice.init()",
            "↓Bundle.init()",
            "↓NSError.init()",
            "let foo = ↓UIDevice.init()",
            "let foo = ↓Bundle.init()",
            "let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init(), error: ↓NSError.init())",
        ])
    )
}

private extension DiscouragedDirectInitRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.arguments.isEmpty, node.trailingClosure == nil,
                  configuration.discouragedInits.contains(node.calledExpression.trimmedDescription) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
