import SwiftOperators
import SwiftSyntax

@SwiftSyntaxRule(foldExpressions: true, optIn: false)
struct PreferIfAndSwitchExpressionsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_if_and_switch_expressions",
        name: "Prefer if and switch expressions",
        description: "Use if and switch expressions instead of performing the same action in all branches",
        kind: .idiomatic,
        nonTriggeringExamples: PreferIfAndSwitchExpressionsRuleExamples.nonTriggeringExamples,
        triggeringExamples: PreferIfAndSwitchExpressionsRuleExamples.triggeringExamples
    )
}

private extension PreferIfAndSwitchExpressionsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            let isElseIfNode = node.parent?.is(IfExprSyntax.self) == true

            if !isElseIfNode,
               let actions = node.actionsInBranches(),
               actionToReplace(actionsInBranches: actions) != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            let cases = node.cases.compactMap { $0.as(SwitchCaseSyntax.self) }
            let actions = cases.map { $0.statements.extractOnlyAction() }

            if actionToReplace(actionsInBranches: actions) != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        /// Compares the actions and return the equivalent action that would replace them.
        func actionToReplace(actionsInBranches actions: [Action?]) -> Action? {
            let validActions = actions.compactMap(\.self)
            guard validActions.count == actions.count else {
                return nil
            }

            let nonThrowActions = validActions.filter { $0 != .throw }
            if nonThrowActions.isEmpty {
                return if validActions.count >= 2 {
                    .throw
                } else {
                    nil
                }
            }

            guard nonThrowActions.count >= 2 else {
                return nil
            }

            let firstAction = nonThrowActions.first
            return if nonThrowActions.dropFirst().allSatisfy({ $0 == firstAction }) {
                firstAction
            } else {
                nil
            }
        }
    }
}

/// An action executed in one branch of an if or switch expression
/// that may cause a violation of the rule.
private enum Action: Equatable {
    case assignment(description: String)
    case `return`
    case `throw`
}

private extension IfExprSyntax {
    /// Retrieves the list of actions.
    /// Returns `nil` if there is no unconditional else block.
    func actionsInBranches() -> [Action?]? {
        guard var actions = actionsInElseBlocks() else {
            return nil
        }

        let thenBlockAction = body.statements.extractOnlyAction()
        actions.append(thenBlockAction)
        return actions
    }

    private func actionsInElseBlocks() -> [Action?]? {
        guard let elseBody else { return nil }

        return switch elseBody {
        case let .ifExpr(ifExprSyntax):
            ifExprSyntax.actionsInBranches()
        case let .codeBlock(finalElse):
            [finalElse.statements.extractOnlyAction()]
        }
    }
}

private extension CodeBlockItemListSyntax {
    func extractOnlyAction() -> Action? {
        guard let statement = onlyElement else { return nil }

        if statement.item.is(ReturnStmtSyntax.self) {
            return .return
        }

        if statement.item.is(ThrowStmtSyntax.self) {
            return .throw
        }

        if let expr = statement.item.as(InfixOperatorExprSyntax.self),
           expr.operator.is(AssignmentExprSyntax.self) {
            return .assignment(description: expr.leftOperand.trimmedDescription)
        }

        return nil
    }
}
