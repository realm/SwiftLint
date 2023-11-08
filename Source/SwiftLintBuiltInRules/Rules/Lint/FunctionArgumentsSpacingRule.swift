import SwiftSyntax


@SwiftSyntaxRule
struct FunctionArgumentsSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    
    static let description = RuleDescription(
        identifier: "functions_arguments_spacing",
        name: "Function Arguments Spacing",
        description: "",
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
            let left = node.leftParen?.trailingTrivia
            
            let arg = node.arguments.last
            if left == Trivia.space {
                violations.append(node.leftParen!.endPositionBeforeTrailingTrivia)
            }
            
            if arg?.trailingTrivia == Trivia.space {
                violations.append(node.rightParen!.positionAfterSkippingLeadingTrivia)
            }
            return
        }
    }
}
