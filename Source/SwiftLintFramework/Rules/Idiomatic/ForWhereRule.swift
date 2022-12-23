import SwiftSyntax

struct ForWhereRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = ForWhereRuleConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "for_where",
        name: "Prefer For-Where",
        description: "`where` clauses are preferred over a single `if` inside a `for`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
            for user in users where user.id == 1 { }
            """),
            // if let
            Example("""
            for user in users {
              if let id = user.id { }
            }
            """),
            // if var
            Example("""
            for user in users {
              if var id = user.id { }
            }
            """),
            // if with else
            Example("""
            for user in users {
              if user.id == 1 { } else { }
            }
            """),
            // if with else if
            Example("""
            for user in users {
              if user.id == 1 {
              } else if user.id == 2 { }
            }
            """),
            // if is not the only expression inside for
            Example("""
            for user in users {
              if user.id == 1 { }
              print(user)
            }
            """),
            // if a variable is used
            Example("""
            for user in users {
              let id = user.id
              if id == 1 { }
            }
            """),
            // if something is after if
            Example("""
            for user in users {
              if user.id == 1 { }
              return true
            }
            """),
            // condition with multiple clauses
            Example("""
            for user in users {
              if user.id == 1 && user.age > 18 { }
            }
            """),
            Example("""
            for user in users {
              if user.id == 1, user.age > 18 { }
            }
            """),
            // if case
            Example("""
            for (index, value) in array.enumerated() {
              if case .valueB(_) = value {
                return index
              }
            }
            """),
            Example("""
            for user in users {
              if user.id == 1 { return true }
            }
            """, configuration: ["allow_for_as_filter": true]),
            Example("""
            for user in users {
              if user.id == 1 {
                let derivedValue = calculateValue(from: user)
                return derivedValue != 0
              }
            }
            """, configuration: ["allow_for_as_filter": true])
        ],
        triggeringExamples: [
            Example("""
            for user in users {
              ↓if user.id == 1 { return true }
            }
            """),
            Example("""
            for subview in subviews {
                ↓if !(subview is UIStackView) {
                    subview.removeConstraints(subview.constraints)
                    subview.removeFromSuperview()
                }
            }
            """),
            Example("""
            for subview in subviews {
                ↓if !(subview is UIStackView) {
                    subview.removeConstraints(subview.constraints)
                    subview.removeFromSuperview()
                }
            }
            """, configuration: ["allow_for_as_filter": true])
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(allowForAsFilter: configuration.allowForAsFilter)
    }
}

private extension ForWhereRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allowForAsFilter: Bool

        init(allowForAsFilter: Bool) {
            self.allowForAsFilter = allowForAsFilter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ForInStmtSyntax) {
            guard node.whereClause == nil,
                  case let statements = node.body.statements,
                  let ifStatement = statements.onlyElement?.item.as(IfStmtSyntax.self),
                  ifStatement.elseBody == nil,
                  !ifStatement.containsOptionalBinding,
                  !ifStatement.containsPatternCondition,
                  let condition = ifStatement.conditions.onlyElement,
                  !condition.containsMultipleConditions else {
                return
            }

            if allowForAsFilter, ifStatement.containsReturnStatement {
                return
            }

            violations.append(ifStatement.positionAfterSkippingLeadingTrivia)
        }
    }
}

private extension IfStmtSyntax {
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
            return operators.contains(binaryExpr.operatorToken.text)
        }
    }
}
