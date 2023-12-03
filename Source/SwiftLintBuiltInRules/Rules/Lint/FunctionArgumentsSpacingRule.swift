import SwiftSyntax

@SwiftSyntaxRule
struct FunctionArgumentsSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "functions_arguments_spacing",
        name: "Function Arguments Spacing",
        description: "Remove the space before the first function argument and after the last argument",
        kind: .lint,
        nonTriggeringExamples: [
            Example("makeGenerator()"),
            Example("makeGenerator(style)"),
            Example("makeGenerator(true, false)")
        ],
        triggeringExamples: [
            Example("makeGenerator(↓ )"),
            Example("makeGenerator(↓ style)"),
            Example("makeGenerator(↓  style)"),
            Example("makeGenerator(style  ↓)"),
            Example("makeGenerator(↓  style  ↓)"),
            Example("makeGenerator(style ↓)"),
            Example("makeGenerator(↓ style ↓)"),
            Example("makeGenerator(↓ offset: 0, limit: 0)"),
            Example("makeGenerator(offset: 0, limit: 0 ↓)"),
            Example("makeGenerator(↓ 1, 2, 3 ↓)"),
            Example("makeGenerator(↓ /* comment */ a)"),
            Example("makeGenerator(a /* other comment */ ↓)"),
            Example("makeGenerator(↓ /* comment */ a /* other comment */)"),
            Example("makeGenerator(/* comment */ a /* other comment */ ↓)"),
            Example("makeGenerator(↓ /* comment */ a /* other comment */ ↓)"),
            Example("makeGenerator(↓  /* comment */ a /* other comment */  ↓)")
        ]
    )
}

private extension TriviaPiece {
    var isSpaces: Bool {
        if case .spaces = self {
            return true
        } else {
            return false
        }
    }
}

private extension FunctionArgumentsSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let leftParan = node.leftParen {
                if let firstArgument = leftParan.trailingTrivia.first {
                    if firstArgument.isSpaces, let leftParen = node.leftParen {
                        violations.append(leftParen.endPositionBeforeTrailingTrivia)
                    }
                }
            }
            let lastArgument = node.arguments.last
            guard lastArgument != nil || node.rightParen != nil else {
                return
            }
            let _lastArgument = lastArgument?.trailingTrivia.reversed().first
            if let lastArg = _lastArgument {
                if lastArg.isSpaces {
                    violations.append(node.rightParen!.positionAfterSkippingLeadingTrivia)
                }
            }
            return
        }
    }
}
