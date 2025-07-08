import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct FunctionNameWhitespaceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "function_name_whitespace",
        name: "Function Name Whitespace",
        description: "Function declaration must have exactly one space before the name and no space after it",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc(lhs: Int, rhs: Int) -> Int {}"),
            Example("func abc<T>(lhs: Int, rhs: Int) -> Int {}"),
            Example("func /* comment */ abc(lhs: Int, rhs: Int) -> Int {}"),
            Example("func /* comment */  abc(lhs: Int, rhs: Int) -> Int {}"),
        ],
        triggeringExamples: [
            Example("func  ↓name(lhs: A, rhs: A) -> A {}"),       // 2 spaces before
            Example("func ↓name (lhs: A, rhs: A) -> A {}"),      // 1 space after
            Example("func  ↓↓name (lhs: A, rhs: A) -> A {}"),    // 1 space after, 2 spaces before
            Example("func ↓name <T>(lhs: Int, rhs: Int) -> Int {}"),
        ],
        corrections: [
            Example("func  name (lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
            Example("func  name(lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
            Example("func   name(lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
            Example("func name (lhs: A, rhs: A) -> A {}"): Example("func name(lhs: A, rhs: A) -> A {}"),
            Example("func name <T>(lhs: Int) -> Int {}"): Example("func name<T>(lhs: Int) -> Int {}"),
        ]
    )
}

private extension FunctionNameWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            guard node.isNamedFunction else { return }
            if !node.funcKeyword.trailingTrivia.isSingleSpace,
               !node.funcKeyword.trailingTrivia.containsComments {
                violations.append(
                    at: node.name.positionAfterSkippingLeadingTrivia,
                    correction: .init(
                        start: node.funcKeyword.endPositionBeforeTrailingTrivia,
                        end: node.name.positionAfterSkippingLeadingTrivia,
                        replacement: " "
                    )
                )
            }
            if node.name.trailingTrivia.isNotEmpty {
                let correctionStart = node.name.endPositionBeforeTrailingTrivia
                let correctionEnd = correctionStart.advanced(
                    by: node.name.trailingTriviaLength.utf8Length
                )

                violations.append(
                    at: node.name.positionAfterSkippingLeadingTrivia,
                    correction: ReasonedRuleViolation.ViolationCorrection(
                        start: correctionStart,
                        end: correctionEnd,
                        replacement: ""
                    )
                )
            }
        }
    }
}

private extension FunctionDeclSyntax {
    var isNamedFunction: Bool {
        guard case .identifier = name.tokenKind else { return false }
        return true
    }
}
