import SwiftSyntax

struct NoSpaceInMethodCallRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "no_space_in_method_call",
        name: "No Space in Method Call",
        description: "Don't add a space between the method name and the parentheses",
        kind: .style,
        nonTriggeringExamples: [
            Example("foo()"),
            Example("object.foo()"),
            Example("object.foo(1)"),
            Example("object.foo(value: 1)"),
            Example("object.foo { print($0 }"),
            Example("list.sorted { $0.0 < $1.0 }.map { $0.value }"),
            Example("self.init(rgb: (Int) (colorInt))"),
            Example("""
            Button {
                print("Button tapped")
            } label: {
                Text("Button")
            }
            """)
        ],
        triggeringExamples: [
            Example("foo↓ ()"),
            Example("object.foo↓ ()"),
            Example("object.foo↓ (1)"),
            Example("object.foo↓ (value: 1)"),
            Example("object.foo↓ () {}"),
            Example("object.foo↓     ()"),
            Example("object.foo↓     (value: 1) { x in print(x) }")
        ],
        corrections: [
            Example("foo↓ ()"): Example("foo()"),
            Example("object.foo↓ ()"): Example("object.foo()"),
            Example("object.foo↓ (1)"): Example("object.foo(1)"),
            Example("object.foo↓ (value: 1)"): Example("object.foo(value: 1)"),
            Example("object.foo↓ () {}"): Example("object.foo() {}"),
            Example("object.foo↓     ()"): Example("object.foo()")
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

private extension NoSpaceInMethodCallRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.hasNoSpaceInMethodCallViolation else {
                return
            }

            violations.append(node.calledExpression.endPositionBeforeTrailingTrivia)
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
            guard
                node.hasNoSpaceInMethodCallViolation,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(node.calledExpression.endPositionBeforeTrailingTrivia)

            let newNode = node
                .with(\.calledExpression, node.calledExpression.with(\.trailingTrivia, []))

            return super.visit(newNode)
        }
    }
}

private extension FunctionCallExprSyntax {
    var hasNoSpaceInMethodCallViolation: Bool {
        guard leftParen != nil,
            !calledExpression.is(TupleExprSyntax.self),
            let trailingTrivia = calledExpression.trailingTrivia,
            trailingTrivia.isNotEmpty else {
            return false
        }

        return true
    }
}
