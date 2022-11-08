import SwiftSyntax

struct EmptyParenthesesWithTrailingClosureRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "empty_parentheses_with_trailing_closure",
        name: "Empty Parentheses with Trailing Closure",
        description: "When using trailing closures, empty parentheses should be avoided " +
                     "after the method call.",
        kind: .style,
        nonTriggeringExamples: [
            Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map({ $0 + 1 })\n"),
            Example("[1, 2].reduce(0) { $0 + $1 }"),
            Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("let isEmpty = [1, 2].isEmpty()\n"),
            Example("""
            UIView.animateWithDuration(0.3, animations: {
               self.disableInteractionRightView.alpha = 0
            }, completion: { _ in
               ()
            })
            """)
        ],
        triggeringExamples: [
            Example("[1, 2].map↓() { $0 + 1 }\n"),
            Example("[1, 2].map↓( ) { $0 + 1 }\n"),
            Example("[1, 2].map↓() { number in\n number + 1 \n}\n"),
            Example("[1, 2].map↓(  ) { number in\n number + 1 \n}\n"),
            Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}\n")
        ],
        corrections: [
            Example("[1, 2].map↓() { $0 + 1 }\n"): Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map↓( ) { $0 + 1 }\n"): Example("[1, 2].map { $0 + 1 }\n"),
            Example("[1, 2].map↓() { number in\n number + 1 \n}\n"):
                Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("[1, 2].map↓(  ) { number in\n number + 1 \n}\n"):
                Example("[1, 2].map { number in\n number + 1 \n}\n"),
            Example("func foo() -> [Int] {\n    return [1, 2].map↓() { $0 + 1 }\n}\n"):
                Example("func foo() -> [Int] {\n    return [1, 2].map { $0 + 1 }\n}\n"),
            Example("class C {\n#if true\nfunc f() {\n[1, 2].map↓() { $0 + 1 }\n}\n#endif\n}"):
                Example("class C {\n#if true\nfunc f() {\n[1, 2].map { $0 + 1 }\n}\n#endif\n}")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension EmptyParenthesesWithTrailingClosureRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let position = node.violationPosition else {
                return
            }

            violations.append(position)
        }
    }

    private final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard
                let violationPosition = node.violationPosition,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            let newNode = node
                .withLeftParen(nil)
                .withRightParen(nil)
                .withTrailingClosure(node.trailingClosure?.withLeadingTrivia(.spaces(1)))
            correctionPositions.append(violationPosition)
            return super.visit(newNode)
        }
    }
}

private extension FunctionCallExprSyntax {
    var violationPosition: AbsolutePosition? {
        guard trailingClosure != nil,
              let leftParen = leftParen,
              argumentList.isEmpty else {
            return nil
        }

        return leftParen.positionAfterSkippingLeadingTrivia
    }
}
