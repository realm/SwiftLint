import SwiftSyntax

struct LegacyMultipleRule: OptInRule, ConfigurationProviderRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "legacy_multiple",
        name: "Legacy Multiple",
        description: "Prefer using the `isMultiple(of:)` function instead of using the remainder operator (`%`)",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("cell.contentView.backgroundColor = indexPath.row.isMultiple(of: 2) ? .gray : .white"),
            Example("guard count.isMultiple(of: 2) else { throw DecodingError.dataCorrupted(...) }"),
            Example("sanityCheck(bytes > 0 && bytes.isMultiple(of: 4), \"capacity must be multiple of 4 bytes\")"),
            Example("guard let i = reversedNumbers.firstIndex(where: { $0.isMultiple(of: 2) }) else { return }"),
            Example("""
            let constant = 56
            let isMultiple = value.isMultiple(of: constant)
            """),
            Example("""
            let constant = 56
            let secret = value % constant == 5
            """),
            Example("let secretValue = (value % 3) + 2")
        ],
        triggeringExamples: [
            Example("cell.contentView.backgroundColor = indexPath.row ↓% 2 == 0 ? .gray : .white"),
            Example("cell.contentView.backgroundColor = 0 == indexPath.row ↓% 2 ? .gray : .white"),
            Example("cell.contentView.backgroundColor = indexPath.row ↓% 2 != 0 ? .gray : .white"),
            Example("guard count ↓% 2 == 0 else { throw DecodingError.dataCorrupted(...) }"),
            Example("sanityCheck(bytes > 0 && bytes ↓% 4 == 0, \"capacity must be multiple of 4 bytes\")"),
            Example("guard let i = reversedNumbers.firstIndex(where: { $0 ↓% 2 == 0 }) else { return }"),
            Example("""
            let constant = 56
            let isMultiple = value ↓% constant == 0
            """)
        ]
    )

    func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
        file.foldedSyntaxTree
    }

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension LegacyMultipleRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard let operatorNode = node.operatorOperand.as(BinaryOperatorExprSyntax.self),
                  operatorNode.operatorToken.tokenKind == .binaryOperator("%"),
                  let parent = node.parent?.as(InfixOperatorExprSyntax.self),
                  let parentOperatorNode = parent.operatorOperand.as(BinaryOperatorExprSyntax.self),
                  parentOperatorNode.isEqualityOrInequalityOperator else {
                return
            }

            let isExprEqualTo0 = {
                parent.leftOperand.as(InfixOperatorExprSyntax.self) == node &&
                    parent.rightOperand.as(IntegerLiteralExprSyntax.self)?.isZero == true
            }

            let is0EqualToExpr = {
                parent.leftOperand.as(IntegerLiteralExprSyntax.self)?.isZero == true &&
                    parent.rightOperand.as(InfixOperatorExprSyntax.self) == node
            }

            guard isExprEqualTo0() || is0EqualToExpr() else {
                return
            }

            violations.append(node.operatorOperand.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension BinaryOperatorExprSyntax {
    var isEqualityOrInequalityOperator: Bool {
        operatorToken.tokenKind == .binaryOperator("==") ||
            operatorToken.tokenKind == .binaryOperator("!=")
    }
}
