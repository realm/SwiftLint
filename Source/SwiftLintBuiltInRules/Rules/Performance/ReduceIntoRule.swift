import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ReduceIntoRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "reduce_into",
        name: "Reduce into",
        description: "Prefer `reduce(into:_:)` over `reduce(_:_:)` for copy-on-write types",
        kind: .performance,
        nonTriggeringExamples: [
            Example("""
            let foo = values.reduce(into: "abc") { $0 += "\\($1)" }
            """),
            Example("""
            values.reduce(into: Array<Int>()) { result, value in
                result.append(value)
            }
            """),
            Example("""
            let rows = violations.enumerated().reduce(into: "") { rows, indexAndViolation in
                rows.append(generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1))
            }
            """),
            Example("""
            zip(group, group.dropFirst()).reduce(into: []) { result, pair in
                result.append(pair.0 + pair.1)
            }
            """),
            Example("""
            let foo = values.reduce(into: [String: Int]()) { result, value in
                result["\\(value)"] = value
            }
            """),
            Example("""
            let foo = values.reduce(into: Dictionary<String, Int>.init()) { result, value in
                result["\\(value)"] = value
            }
            """),
            Example("""
            let foo = values.reduce(into: [Int](repeating: 0, count: 10)) { result, value in
                result.append(value)
            }
            """),
            Example("""
            let foo = values.reduce(MyClass()) { result, value in
                result.handleValue(value)
                return result
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            let bar = values.↓reduce("abc") { $0 + "\\($1)" }
            """),
            Example("""
            values.↓reduce(Array<Int>()) { result, value in
                result += [value]
            }
            """),
            Example("""
            [1, 2, 3].↓reduce(Set<Int>()) { acc, value in
                var result = acc
                result.insert(value)
                return result
            }
            """),
            Example("""
            let rows = violations.enumerated().↓reduce("") { rows, indexAndViolation in
                return rows + generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1)
            }
            """),
            Example("""
            zip(group, group.dropFirst()).↓reduce([]) { result, pair in
                result + [pair.0 + pair.1]
            }
            """),
            Example("""
            let foo = values.↓reduce([String: Int]()) { result, value in
                var result = result
                result["\\(value)"] = value
                return result
            }
            """),
            Example("""
            let bar = values.↓reduce(Dictionary<String, Int>.init()) { result, value in
                var result = result
                result["\\(value)"] = value
                return result
            }
            """),
            Example("""
            let bar = values.↓reduce([Int](repeating: 0, count: 10)) { result, value in
                return result + [value]
            }
            """),
            Example("""
            extension Data {
                var hexString: String {
                    return ↓reduce("") { (output, byte) -> String in
                        output + String(format: "%02x", byte)
                    }
                }
            }
            """),
        ]
    )
}

private extension ReduceIntoRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let name = node.nameToken,
                  name.text == "reduce",
                  node.arguments.count == 2 || (node.arguments.count == 1 && node.trailingClosure != nil),
                  let firstArgument = node.arguments.first,
                  // would otherwise equal "into"
                  firstArgument.label == nil,
                  firstArgument.expression.isCopyOnWriteType else {
                return
            }

            violations.append(name.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension FunctionCallExprSyntax {
    var nameToken: TokenSyntax? {
        if let expr = calledExpression.as(MemberAccessExprSyntax.self) {
            return expr.declName.baseName
        }
        if let expr = calledExpression.as(DeclReferenceExprSyntax.self) {
            return expr.baseName
        }

        return nil
    }
}

private extension ExprSyntax {
    var isCopyOnWriteType: Bool {
        if self.is(StringLiteralExprSyntax.self) ||
            self.is(DictionaryExprSyntax.self) ||
            self.is(ArrayExprSyntax.self) {
            return true
        }

        if let expr = self.as(FunctionCallExprSyntax.self) {
            if let identifierExpr = expr.calledExpression.identifierExpr {
                return identifierExpr.isCopyOnWriteType
            }
            if let memberAccesExpr = expr.calledExpression.as(MemberAccessExprSyntax.self),
                      memberAccesExpr.declName.baseName.text == "init",
                      let identifierExpr = memberAccesExpr.base?.identifierExpr {
                return identifierExpr.isCopyOnWriteType
            }
            if expr.calledExpression.isCopyOnWriteType {
                return true
            }
        }

        return false
     }

    var identifierExpr: DeclReferenceExprSyntax? {
        if let identifierExpr = self.as(DeclReferenceExprSyntax.self) {
            return identifierExpr
        }
        if let specializeExpr = self.as(GenericSpecializationExprSyntax.self) {
            return specializeExpr.expression.identifierExpr
        }

        return nil
    }
}

private extension DeclReferenceExprSyntax {
    private static let copyOnWriteTypes: Set = ["Array", "Dictionary", "Set"]

    var isCopyOnWriteType: Bool {
        Self.copyOnWriteTypes.contains(baseName.text)
    }
}
