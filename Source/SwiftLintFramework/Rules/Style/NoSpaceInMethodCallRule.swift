import SwiftSyntax

public struct NoSpaceInMethodCallRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "no_space_in_method_call",
        name: "No Space in Method Call",
        description: "Don't add a space between the method name and the parentheses.",
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

private extension NoSpaceInMethodCallRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.hasNoSpaceInMethodCallViolation else {
                return
            }

            violationPositions.append(node.calledExpression.endPositionBeforeTrailingTrivia)
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
            guard node.hasNoSpaceInMethodCallViolation else {
                return super.visit(node)
            }

            let isInDisabledRegion = disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }

            guard !isInDisabledRegion else {
                return super.visit(node)
            }

            correctionPositions.append(node.calledExpression.endPositionBeforeTrailingTrivia)

            let newNode = node
                .withCalledExpression(node.calledExpression.withoutTrailingTrivia())

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
