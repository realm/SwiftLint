import SwiftSyntax

struct EmptyCountRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    var configuration = EmptyCountConfiguration()

    static let description = RuleDescription(
        identifier: "empty_count",
        name: "Empty Count",
        description: "Prefer checking `isEmpty` over comparing `count` to zero",
        kind: .performance,
        nonTriggeringExamples: [
            Example("var count = 0"),
            Example("[Int]().isEmpty"),
            Example("[Int]().count > 1"),
            Example("[Int]().count == 1"),
            Example("[Int]().count == 0xff"),
            Example("[Int]().count == 0b01"),
            Example("[Int]().count == 0o07"),
            Example("discount == 0"),
            Example("order.discount == 0")
        ],
        triggeringExamples: [
            Example("[Int]().↓count == 0"),
            Example("0 == [Int]().↓count"),
            Example("[Int]().↓count==0"),
            Example("[Int]().↓count > 0"),
            Example("[Int]().↓count != 0"),
            Example("[Int]().↓count == 0x0"),
            Example("[Int]().↓count == 0x00_00"),
            Example("[Int]().↓count == 0b00"),
            Example("[Int]().↓count == 0o00"),
            Example("↓count == 0")
        ]
    )

    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
        file.foldedSyntaxTree
    }

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(onlyAfterDot: configuration.onlyAfterDot)
    }
}

private extension EmptyCountRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let onlyAfterDot: Bool

        init(onlyAfterDot: Bool) {
            self.onlyAfterDot = onlyAfterDot
            super.init(viewMode: .sourceAccurate)
        }

        private let operators: Set = ["==", "!=", ">", ">=", "<", "<="]

        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let operatorNode = node.operatorOperand.as(BinaryOperatorExprSyntax.self),
                  let binaryOperator = operatorNode.operatorToken.binaryOperator,
                  operators.contains(binaryOperator) else {
                return
            }

            if let intExpr = node.rightOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
               let position = node.leftOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
                violations.append(position)
                return
            }

            if let intExpr = node.leftOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
               let position = node.rightOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
                violations.append(position)
                return
            }
        }
    }
}

private extension ExprSyntax {
    func countCallPosition(onlyAfterDot: Bool) -> AbsolutePosition? {
        if let expr = self.as(MemberAccessExprSyntax.self) {
            if expr.declNameArguments == nil && expr.name.tokenKind == .identifier("count") {
                return expr.name.positionAfterSkippingLeadingTrivia
            }

            return nil
        }

        if !onlyAfterDot, let expr = self.as(IdentifierExprSyntax.self) {
            return expr.identifier.tokenKind == .identifier("count") ? expr.positionAfterSkippingLeadingTrivia : nil
        }

        return nil
    }
}

private extension TokenSyntax {
    var binaryOperator: String? {
        switch tokenKind {
        case .binaryOperator(let str):
            return str
        default:
            return nil
        }
    }
}
