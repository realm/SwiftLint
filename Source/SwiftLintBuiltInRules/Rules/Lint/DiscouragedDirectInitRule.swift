import SwiftSyntax

struct DiscouragedDirectInitRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = DiscouragedDirectInitConfiguration()

    static let description = RuleDescription(
        identifier: "discouraged_direct_init",
        name: "Discouraged Direct Initialization",
        description: "Discouraged direct initialization of types that can be harmful",
        kind: .lint,
        nonTriggeringExamples: [
            "let foo = UIDevice.current",
            "let foo = Bundle.main",
            "let foo = Bundle(path: \"bar\")",
            "let foo = Bundle(identifier: \"bar\")",
            "let foo = Bundle.init(path: \"bar\")",
            "let foo = Bundle.init(identifier: \"bar\")",
            "let foo = NSError(domain: \"bar\", code: 0)",
            "let foo = NSError.init(domain: \"bar\", code: 0)",
            "func testNSError()"
        ],
        triggeringExamples: [
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
            "let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init(), error: ↓NSError.init())"
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
                discouragedInits.contains(node.calledExpression.trimmedDescription) else {
                return
            }

            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}
