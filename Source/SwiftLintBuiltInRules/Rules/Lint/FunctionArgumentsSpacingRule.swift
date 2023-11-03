import SwiftSyntax


@SwiftSyntaxRule
struct FunctionArgumentsSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    
    static let description = RuleDescription(
        identifier: "functions_arguments_spacing",
        name: "Function Arguments Spacing",
        description: "Remove spaces before the function argument and after the function argument",
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
            // before
            print("=============================================")
            print(node.arguments.first?.expression.description)
            print(node.arguments.first?.expression.leadingTrivia.isEmpty)
            print("aaaaaaaaaaaaaaaaaaaaaa")
            print(node.arguments.first!.expression.positionAfterSkippingLeadingTrivia)
            if (!node.arguments.first!.expression.leadingTrivia.isEmpty) {
                print("----------------------------")
                violations.append(node.arguments.first!.expression.positionAfterSkippingLeadingTrivia)
            }
            
        }
    }
}
