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
            Example("testFunc()"),
            Example("testFunc(style)"),
            Example("testFunc(true, false)"),
            Example("""
            makeGenerator(
                a: true,
                b: false
            )
            """)
        ],
        triggeringExamples: [
            Example("testFunc(↓ )"),
            Example("testFunc(↓ style)"),
            Example("testFunc(↓  style)"),
            Example("testFunc(style  ↓)"),
            Example("testFunc(↓  style  ↓)"),
            Example("testFunc(style ↓)"),
            Example("testFunc(↓ style ↓)"),
            Example("testFunc(↓ offset: 0, limit: 0)"),
            Example("testFunc(offset: 0, limit: 0 ↓)"),
            Example("testFunc(↓ 1, 2, 3 ↓)"),
            Example("testFunc(↓ /* comment */ a)"),
            Example("testFunc(a /* other comment */ ↓)"),
            Example("testFunc(↓ /* comment */ a /* other comment */)"),
            Example("testFunc(/* comment */ a /* other comment */ ↓)"),
            Example("testFunc(↓ /* comment */ a /* other comment */ ↓)"),
            Example("testFunc(↓  /* comment */ a /* other comment */  ↓)")
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
        /*
         Because it is not sure at which node SwiftSyntax will put a space,
         it checks the trivia at each of the variables and at the paren.
         */
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let leftParen = node.leftParen, let rightParen = node.rightParen else { return }
            let firstArgument = node.arguments.first
            // Check that the trivia immediately following the leftParen is spaces(_:),
            // as it may contain trivia that is not space like blockComment(_:)
            if let firstArgumentLeadingTrivia = firstArgument?.leadingTrivia,
               !firstArgumentLeadingTrivia.containsNewlines() {
                    if let firstElementTrivia = firstArgumentLeadingTrivia.pieces.last {
                        if firstElementTrivia.isSpaces {
                            violations.append(leftParen.positionAfterSkippingLeadingTrivia)
                        }
                    }
            }
            if let trailingTrivia = leftParen.trailingTrivia.first {
                if trailingTrivia.isSpaces {
                    violations.append(leftParen.endPositionBeforeTrailingTrivia)
                }
            }
            let lastArgument = node.arguments.last
            // Check that the trivia immediately preceding the rightParen is spaces(_:),
            // as it may contain trivia that is not space like blockComment(_:)
            if let lastElementTrivia = lastArgument?.trailingTrivia.reversed().first {
                if lastElementTrivia.isSpaces {
                    violations.append(rightParen.positionAfterSkippingLeadingTrivia)
                }
            }
            if let firstArgument = rightParen.leadingTrivia.first {
                if firstArgument.isSpaces, let rightParan = node.rightParen {
                    violations.append(rightParan.endPositionBeforeTrailingTrivia)
                }
            }
        }
    }
}
