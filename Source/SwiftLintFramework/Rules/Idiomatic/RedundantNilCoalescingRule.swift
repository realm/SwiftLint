import SwiftSyntax

public struct RedundantNilCoalescingRule: OptInRule, SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
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

private extension RedundantNilCoalescingRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: TokenSyntax) {
            if node.tokenKind.isNilCoalescingOperator && node.nextToken?.tokenKind == .nilKeyword {
                violationPositions.append(node.position)
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

        override func visit(_ node: ExprListSyntax) -> Syntax {
            guard
                node.count > 2,
                let lastExpression = node.last,
                lastExpression.is(NilLiteralExprSyntax.self),
                let secondToLastExpression = node.dropLast().last?.as(BinaryOperatorExprSyntax.self),
                secondToLastExpression.operatorToken.tokenKind.isNilCoalescingOperator
            else {
                return super.visit(node)
            }

            let isInDisabledRegion = disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }

            guard !isInDisabledRegion else {
                return super.visit(node)
            }

            let newNode = node.removingLast().removingLast().withoutTrailingTrivia()
            correctionPositions.append(newNode.endPosition)
            return super.visit(newNode)
        }
    }
}

private extension TokenKind {
    var isNilCoalescingOperator: Bool {
        self == .spacedBinaryOperator("??") || self == .unspacedBinaryOperator("??")
    }
}
