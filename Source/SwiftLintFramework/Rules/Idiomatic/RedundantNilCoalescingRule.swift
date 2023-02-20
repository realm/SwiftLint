import SwiftSyntax

struct RedundantNilCoalescingRule: OptInRule, SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "redundant_nil_coalescing",
        name: "Redundant Nil Coalescing",
        description: "nil coalescing operator is only evaluated if the lhs is nil" +
            ", coalescing operator with nil as rhs is redundant",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var myVar: Int?; myVar ?? 0\n")
        ],
        triggeringExamples: [
            Example("var myVar: Int? = nil; myVar ↓?? nil\n")
        ],
        corrections: [
            Example("var myVar: Int? = nil; let foo = myVar↓ ?? nil\n"):
                Example("var myVar: Int? = nil; let foo = myVar\n")
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

private extension RedundantNilCoalescingRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TokenSyntax) {
            if node.tokenKind.isNilCoalescingOperator && node.nextToken?.tokenKind == .keyword(.nil) {
                violations.append(node.position)
            }
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

        override func visit(_ node: ExprListSyntax) -> ExprListSyntax {
            guard
                node.count > 2,
                let lastExpression = node.last,
                lastExpression.is(NilLiteralExprSyntax.self),
                let secondToLastExpression = node.dropLast().last?.as(BinaryOperatorExprSyntax.self),
                secondToLastExpression.operatorToken.tokenKind.isNilCoalescingOperator,
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            let newNode = node.removingLast().removingLast().with(\.trailingTrivia, [])
            correctionPositions.append(newNode.endPosition)
            return super.visit(newNode)
        }
    }
}

private extension TokenKind {
    var isNilCoalescingOperator: Bool {
        self == .binaryOperator("??")
    }
}
