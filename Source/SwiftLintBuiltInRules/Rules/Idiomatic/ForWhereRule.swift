import SwiftSyntax

@SwiftSyntaxRule
struct ForWhereRule: Rule {
    var configuration = ForWhereConfiguration()

    static let description = RuleDescription(
        identifier: "for_where",
        name: "Prefer For-Where",
        description: "`where` clauses are preferred over a single `if` inside a `for`",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            """
            for user in users where user.id == 1 { }
            """,
            // if let
            """
            for user in users {
              if let id = user.id { }
            }
            """,
            // if var
            """
            for user in users {
              if var id = user.id { }
            }
            """,
            // if with else
            """
            for user in users {
              if user.id == 1 { } else { }
            }
            """,
            // if with else if
            """
            for user in users {
              if user.id == 1 {
              } else if user.id == 2 { }
            }
            """,
            // if is not the only expression inside for
            """
            for user in users {
              if user.id == 1 { }
              print(user)
            }
            """,
            // if a variable is used
            """
            for user in users {
              let id = user.id
              if id == 1 { }
            }
            """,
            // if something is after if
            """
            for user in users {
              if user.id == 1 { }
              return true
            }
            """,
            // condition with multiple clauses
            """
            for user in users {
              if user.id == 1 && user.age > 18 { }
            }
            """,
            """
            for user in users {
              if user.id == 1, user.age > 18 { }
            }
            """,
            // if case
            """
            for (index, value) in array.enumerated() {
              if case .valueB(_) = value {
                return index
              }
            }
            """,
            """
            for user in users {
              if user.id == 1 { return true }
            }
            """.configuration(["allow_for_as_filter": true]),
            """
            for user in users {
              if user.id == 1 {
                let derivedValue = calculateValue(from: user)
                return derivedValue != 0
              }
            }
            """.configuration(["allow_for_as_filter": true]),
        ]),
        triggeringExamples: #examples([
            """
            for user in users {
              ↓if user.id == 1 { return true }
            }
            """,
            """
            for subview in subviews {
                ↓if !(subview is UIStackView) {
                    subview.removeConstraints(subview.constraints)
                    subview.removeFromSuperview()
                }
            }
            """,
            """
            for subview in subviews {
                ↓if !(subview is UIStackView) {
                    subview.removeConstraints(subview.constraints)
                    subview.removeFromSuperview()
                }
            }
            """.configuration(["allow_for_as_filter": true]),
        ])
    )
}

private extension ForWhereRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ForStmtSyntax) {
            guard node.whereClause == nil,
                  let onlyExprStmt = node.body.statements.onlyElement?.item.as(ExpressionStmtSyntax.self),
                  let ifExpr = onlyExprStmt.expression.as(IfExprSyntax.self),
                  ifExpr.elseBody == nil,
                  !ifExpr.containsOptionalBinding,
                  !ifExpr.containsPatternCondition,
                  let condition = ifExpr.conditions.onlyElement,
                  !condition.containsMultipleConditions else {
                return
            }

            if configuration.allowForAsFilter, ifExpr.containsReturnStatement {
                return
            }

            violations.append(ifExpr.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension IfExprSyntax {
    var containsOptionalBinding: Bool {
        conditions.contains { element in
            element.condition.is(OptionalBindingConditionSyntax.self)
        }
    }

    var containsPatternCondition: Bool {
        conditions.contains { element in
            element.condition.is(MatchingPatternConditionSyntax.self)
        }
    }

    var containsReturnStatement: Bool {
        body.statements.contains { element in
            element.item.is(ReturnStmtSyntax.self)
        }
    }
}

private extension ConditionElementSyntax {
    var containsMultipleConditions: Bool {
        guard let condition = condition.as(SequenceExprSyntax.self) else {
            return false
        }

        return condition.elements.contains { expr in
            guard let binaryExpr = expr.as(BinaryOperatorExprSyntax.self) else {
                return false
            }

            let operators: Set = ["&&", "||"]
            return operators.contains(binaryExpr.operator.text)
        }
    }
}
