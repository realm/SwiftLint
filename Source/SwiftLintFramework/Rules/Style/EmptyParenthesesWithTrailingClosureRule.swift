import SwiftSyntax

public struct EmptyParenthesesWithTrailingClosureRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension EmptyParenthesesWithTrailingClosureRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let position = node.violationPosition else {
                return
            }

            violationPositions.append(position)
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
            guard let violationPosition = node.violationPosition else {
                return super.visit(node)
            }

            let isInDisabledRegion = disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }

            guard !isInDisabledRegion else {
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
