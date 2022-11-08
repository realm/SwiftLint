import SwiftSyntax

struct DiscouragedDirectInitRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = DiscouragedDirectInitConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "discouraged_direct_init",
        name: "Discouraged Direct Initialization",
        description: "Discouraged direct initialization of types that can be harmful.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let foo = UIDevice.current"),
            Example("let foo = Bundle.main"),
            Example("let foo = Bundle(path: \"bar\")"),
            Example("let foo = Bundle(identifier: \"bar\")"),
            Example("let foo = Bundle.init(path: \"bar\")"),
            Example("let foo = Bundle.init(identifier: \"bar\")"),
            Example("let foo = NSError(domain: \"bar\", code: 0)"),
            Example("let foo = NSError.init(domain: \"bar\", code: 0)"),
            Example("func testNSError()")
        ],
        triggeringExamples: [
            Example("↓UIDevice()"),
            Example("↓Bundle()"),
            Example("let foo = ↓UIDevice()"),
            Example("let foo = ↓Bundle()"),
            Example("let foo = ↓NSError()"),
            Example("let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice(), error: ↓NSError())"),
            Example("↓UIDevice.init()"),
            Example("↓Bundle.init()"),
            Example("↓NSError.init()"),
            Example("let foo = ↓UIDevice.init()"),
            Example("let foo = ↓Bundle.init()"),
            Example("let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init(), error: ↓NSError.init())")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(discouragedInits: configuration.discouragedInits)
    }
}

private extension DiscouragedDirectInitRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let discouragedInits: Set<String>

        init(discouragedInits: Set<String>) {
            self.discouragedInits = discouragedInits
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.argumentList.isEmpty, node.trailingClosure == nil,
                discouragedInits.contains(node.calledExpression.withoutTrivia().description) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
