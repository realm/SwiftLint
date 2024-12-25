import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true, optIn: true)
struct EmptyCountRule: Rule {
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
            Example("order.discount == 0"),
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
            Example("↓count == 0"),
        ],
        corrections: [
            Example("[].↓count == 0"):
                Example("[].isEmpty"),
            Example("0 == [].↓count"):
                Example("[].isEmpty"),
            Example("[Int]().↓count == 0"):
                Example("[Int]().isEmpty"),
            Example("0 == [Int]().↓count"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count==0"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count > 0"):
                Example("![Int]().isEmpty"),
            Example("[Int]().↓count != 0"):
                Example("![Int]().isEmpty"),
            Example("[Int]().↓count == 0x0"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count == 0x00_00"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count == 0b00"):
                Example("[Int]().isEmpty"),
            Example("[Int]().↓count == 0o00"):
                Example("[Int]().isEmpty"),
            Example("↓count == 0"):
                Example("isEmpty"),
            Example("↓count == 0 && [Int]().↓count == 0o00"):
                Example("isEmpty && [Int]().isEmpty"),
            Example("[Int]().count != 3 && [Int]().↓count != 0 || ↓count == 0 && [Int]().count > 2"):
                Example("[Int]().count != 3 && ![Int]().isEmpty || isEmpty && [Int]().count > 2"),
        ]
    )
}

private extension EmptyCountRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let binaryOperator = node.binaryOperator, binaryOperator.isComparison else {
                return
            }

            if let (_, position) = node.countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot) {
                violations.append(position)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard let binaryOperator = node.binaryOperator, binaryOperator.isComparison else {
                return super.visit(node)
            }

            if let (count, position) = node.countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot) {
                let newNode =
                    if let count = count.as(MemberAccessExprSyntax.self) {
                        ExprSyntax(count.with(\.declName.baseName, "isEmpty").trimmed)
                    } else {
                        ExprSyntax(count.as(DeclReferenceExprSyntax.self)?.with(\.baseName, "isEmpty").trimmed)
                    }
                guard let newNode else { return super.visit(node) }
                correctionPositions.append(position)
                return
                    if ["!=", "<", ">"].contains(binaryOperator) {
                        newNode.negated
                            .withTrivia(from: node)
                    } else {
                        newNode
                            .withTrivia(from: node)
                    }
            }
            return super.visit(node)
        }
    }
}

private extension ExprSyntax {
    func countCallPosition(onlyAfterDot: Bool) -> AbsolutePosition? {
        if let expr = self.as(MemberAccessExprSyntax.self) {
            if expr.declName.argumentNames == nil && expr.declName.baseName.tokenKind == .identifier("count") {
                return expr.declName.baseName.positionAfterSkippingLeadingTrivia
            }

            return nil
        }

        if !onlyAfterDot, let expr = self.as(DeclReferenceExprSyntax.self) {
            return expr.baseName.tokenKind == .identifier("count") ? expr.positionAfterSkippingLeadingTrivia : nil
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

private extension ExprSyntaxProtocol {
    var negated: ExprSyntax {
        ExprSyntax(PrefixOperatorExprSyntax(operator: .prefixOperator("!"), expression: self))
    }
}

private extension SyntaxProtocol {
    func withTrivia(from node: some SyntaxProtocol) -> Self {
        self
            .with(\.leadingTrivia, node.leadingTrivia)
            .with(\.trailingTrivia, node.trailingTrivia)
    }
}

private extension InfixOperatorExprSyntax {
    func countNodeAndPosition(onlyAfterDot: Bool) -> (ExprSyntax, AbsolutePosition)? {
        if let intExpr = rightOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
           let position = leftOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
            return (leftOperand, position)
        }
        if let intExpr = leftOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
           let position = rightOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
            return (rightOperand, position)
        }
        return nil
    }

    var binaryOperator: String? {
        self.operator.as(BinaryOperatorExprSyntax.self)?.operator.binaryOperator
    }
}

private extension String {
    private static let operators: Set = ["==", "!=", ">", ">=", "<", "<="]
    var isComparison: Bool {
        String.operators.contains(self)
    }
}
