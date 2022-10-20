import SwiftSyntax

public struct EmptyCountRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    public var configuration = EmptyCountConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_count",
        name: "Empty Count",
        description: "Prefer checking `isEmpty` over comparing `count` to zero.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("var count = 0\n"),
            Example("[Int]().isEmpty\n"),
            Example("[Int]().count > 1\n"),
            Example("[Int]().count == 1\n"),
            Example("[Int]().count == 0xff\n"),
            Example("[Int]().count == 0b01\n"),
            Example("[Int]().count == 0o07\n"),
            Example("discount == 0\n"),
            Example("order.discount == 0\n")
        ],
        triggeringExamples: [
            Example("[Int]().↓count == 0\n"),
            Example("0 == [Int]().↓count\n"),
            Example("[Int]().↓count==0\n"),
            Example("[Int]().↓count > 0\n"),
            Example("[Int]().↓count != 0\n"),
            Example("[Int]().↓count == 0x0\n"),
            Example("[Int]().↓count == 0x00_00\n"),
            Example("[Int]().↓count == 0b00\n"),
            Example("[Int]().↓count == 0o00\n"),
            Example("↓count == 0\n")
        ]
    )

    public func preprocess(syntaxTree: SourceFileSyntax) -> SourceFileSyntax? {
        syntaxTree.folded()
    }

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
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
        case .spacedBinaryOperator(let str), .unspacedBinaryOperator(let str):
            return str
        default:
            return nil
        }
    }
}

private extension IntegerLiteralExprSyntax {
    var isZero: Bool {
        guard case var .integerLiteral(number) = digits.tokenKind else {
            return false
        }

        number = number.lowercased()
        for prefix in ["0x", "0o", "0b"] {
            number = number.deletingPrefix(prefix)
        }

        number = number.replacingOccurrences(of: "_", with: "")
        return Int(number) == 0
    }
}

private extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}
