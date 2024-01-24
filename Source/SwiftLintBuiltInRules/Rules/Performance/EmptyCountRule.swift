import SwiftLintCore
import SwiftOperators
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true)
struct EmptyCountRule: SwiftSyntaxCorrectableRule, OptInRule {
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
                Example("isEmpty && [Int]().isEmpty")
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            configuration: configuration,
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension EmptyCountRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {

        override func visitPost(_ node: InfixOperatorExprSyntax) {
            guard node.hasBinaryOperator else {
                return
            }

            if let (_, position) = node.countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot) {
                violations.append(position)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter {
        private let configuration: EmptyCountConfiguration

        init(configuration: EmptyCountConfiguration,
             locationConverter: SourceLocationConverter,
             disabledRegions: [SourceRange]) {
            self.configuration = configuration
            super.init(locationConverter: locationConverter, disabledRegions: disabledRegions)
        }

        override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
            guard let folded = try? OperatorTable.standardOperators.foldSingle(node) else { return super.visit(node) }

            if let infix = folded.as(InfixOperatorExprSyntax.self) {
                return visit(infix)
            } else {
                return super.visit(folded)
            }
        }

        override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
            guard node.hasBinaryOperator else {
                return super.visit(node)
            }

            if let (count, position) = node.countNodeAndPosition(onlyAfterDot: configuration.onlyAfterDot) {
                let newNode: ExprSyntax? = if let count = count.as(MemberAccessExprSyntax.self) {
                    count.with(\.declName.baseName, "isEmpty").trimmed.as(ExprSyntax.self)
                } else if let count = count.as(DeclReferenceExprSyntax.self) {
                    count.with(\.baseName, "isEmpty").trimmed.as(ExprSyntax.self)
                } else {
                    nil
                }

                if let newNode, let binaryOperator = node.binaryOperator {
                    correctionPositions.append(position)
                    if ["!=", "<", ">"].contains(binaryOperator) {
                        return newNode.negated
                            .withTrivia(from: node)
                    } else {
                        return ExprSyntax(newNode)
                            .withTrivia(from: node)
                    }
                } else {
                    let left = node.leftOperand.is(InfixOperatorExprSyntax.self)
                    ? visit(node.leftOperand.as(InfixOperatorExprSyntax.self)!) : node.leftOperand
                    let right = node.rightOperand.is(InfixOperatorExprSyntax.self)
                    ? visit(node.rightOperand.as(InfixOperatorExprSyntax.self)!) : node.rightOperand
                    return super.visit(
                        InfixOperatorExprSyntax(leftOperand: left, operator: node.operator, rightOperand: right))
                    .withTrivia(from: node)
                }
            } else {
                return super.visit(node)
            }
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
    private static let operators: Set = ["==", "!=", ">", ">=", "<", "<="]

    func countNodeAndPosition(onlyAfterDot: Bool) -> (ExprSyntax, AbsolutePosition)? {
        if let intExpr = rightOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
           let position = leftOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
            return (leftOperand, position)
        } else if let intExpr = leftOperand.as(IntegerLiteralExprSyntax.self), intExpr.isZero,
                  let position = rightOperand.countCallPosition(onlyAfterDot: onlyAfterDot) {
            return (rightOperand, position)
        } else {
            return nil
        }
    }

    var binaryOperator: String? {
        self.operator.as(BinaryOperatorExprSyntax.self)?.operator.binaryOperator
    }

    var hasBinaryOperator: Bool {
        guard let binaryOperator, InfixOperatorExprSyntax.operators.contains(binaryOperator) else {
            return false
        }

        return true
    }
}
