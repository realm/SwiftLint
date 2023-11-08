import SwiftSyntax

@SwiftSyntaxRule
struct FunctionArgumentsSpacingRule: OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "functions_arguments_spacing",
        name: "Function Arguments Spacing",
        description: "Remove the space before the first function argument and after the last argument",
        kind: .lint
    )
}

private extension FunctionArgumentsSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let argsCount = node.arguments.count
            guard argsCount != 0 else {
                return
            }

            let leftParanTrailingTrivia = node.leftParen?.trailingTrivia
            if leftParanTrailingTrivia == Trivia.space {
                violations.append(node.leftParen!.endPositionBeforeTrailingTrivia)
            }

            let lastArgument = node.arguments.last
            guard lastArgument != nil else {
                return
            }
            if lastArgument!.trailingTrivia == Trivia.space {
                violations.append(node.rightParen!.positionAfterSkippingLeadingTrivia)
            }
            return
        }
    }
}
