import SwiftOperators
import SwiftSyntax

@SwiftSyntaxRule
struct PreferIfAndSwitchExpressionsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "prefer_if_and_switch_expressions",
        name: "Prefer if and switch expressions",
        description: "Use if and switch expressions instead of statements that perform similar actions in its branches",
        kind: .idiomatic,
        nonTriggeringExamples: PreferIfAndSwitchExpressionsRuleExamples.nonTriggeringExamples,
        triggeringExamples: PreferIfAndSwitchExpressionsRuleExamples.triggeringExamples
    )
}

private extension PreferIfAndSwitchExpressionsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: IfExprSyntax) {
            guard node.parent?.is(IfExprSyntax.self) != true else { return }

            if let actions = node.actionInBranches(), actionToReplace(actionsInBranches: actions) != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            let cases = node.cases.compactMap { $0.as(SwitchCaseSyntax.self) }
            let actions = cases.map { $0.statements.extractSingleAction() }
            if actionToReplace(actionsInBranches: actions) != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        /// Compares the actions and return the equivalent action that would replace them.
        func actionToReplace(actionsInBranches actions: [Action?]) -> Action? {
            let validActions = actions.filter { $0 != .throw }

            let nonNilActions = validActions.compactMap { $0 }
            guard nonNilActions.count == validActions.count, nonNilActions.count >= 2 else {
                return nil
            }

            return if nonNilActions.dropFirst().allSatisfy({ $0 == nonNilActions.first }) {
                nonNilActions.first
            } else {
                nil
            }
        }
    }
}

/// Represents an action executed in one branch of an if or switch expression
/// that may cause a violation of the rule.
private enum Action: Equatable {
    case assignment(identifier: String)
    case `return`
    case `throw`
}

private extension IfExprSyntax {
    /// Retrieves the list of `Action`.
    /// Returns `nil` if there is no unconditional else block.
    func actionInBranches() -> [Action?]? {
        guard let elseBody else { return nil }

        var branchesActions = switch elseBody {
        case let .ifExpr(ifExprSyntax):
            ifExprSyntax.actionInBranches()
        case let .codeBlock(finalElse):
            [finalElse.statements.extractSingleAction()]
        }

        if branchesActions != nil {
            let thenBlockAction = body.statements.extractSingleAction()
            branchesActions?.append(thenBlockAction)
        }

        return branchesActions
    }
}

private extension CodeBlockItemListSyntax {
    /// Extracts the only action in the block.
    func extractSingleAction() -> Action? {
        guard let statement = onlyElement else { return nil }

        if statement.item.is(ReturnStmtSyntax.self) {
            return .return
        }

        if statement.item.is(ThrowStmtSyntax.self) {
            return .throw
        }

        if
            let sequenceExpr = statement.item.as(SequenceExprSyntax.self),
            let folded = try? OperatorTable.standardOperators.foldSingle(sequenceExpr),
            let operatorExpr = folded.as(InfixOperatorExprSyntax.self),
            operatorExpr.operator.is(AssignmentExprSyntax.self),
            let declReference = operatorExpr.leftOperand.as(DeclReferenceExprSyntax.self) {
            return .assignment(identifier: declReference.baseName.text)
        }

        return nil
    }
}
