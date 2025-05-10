import SwiftSyntax

@SwiftSyntaxRule(correctable: true)
struct ReturnArrowWhitespaceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "return_arrow_whitespace",
        name: "Returning Whitespace",
        description: "Return arrow and return type should be separated by a single space or on a " +
                     "separate line",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc() -> Int {}"),
            Example("func abc() -> [Int] {}"),
            Example("func abc() -> (Int, Int) {}"),
            Example("var abc = {(param: Int) -> Void in }"),
            Example("func abc() ->\n    Int {}"),
            Example("func abc()\n    -> Int {}"),
            Example("""
            func reallyLongFunctionMethods<T>(withParam1: Int, param2: String, param3: Bool) where T: AGenericConstraint
                -> Int {
                return 1
            }
            """),
            Example("typealias SuccessBlock = ((Data) -> Void)"),
        ],
        triggeringExamples: [
            Example("func abc()↓->Int {}"),
            Example("func abc()↓->[Int] {}"),
            Example("func abc()↓->(Int, Int) {}"),
            Example("func abc()↓-> Int {}"),
            Example("func abc()↓->   Int {}"),
            Example("func abc()↓ ->Int {}"),
            Example("func abc()↓  ->  Int {}"),
            Example("var abc = {(param: Int)↓ ->Bool in }"),
            Example("var abc = {(param: Int)↓->Bool in }"),
            Example("typealias SuccessBlock = ((Data)↓->Void)"),
            Example("func abc()\n  ↓->  Int {}"),
            Example("func abc()\n ↓->  Int {}"),
            Example("func abc()↓  ->\n  Int {}"),
            Example("func abc()↓  ->\nInt {}"),
        ],
        corrections: [
            Example("func abc()↓->Int {}"): Example("func abc() -> Int {}"),
            Example("func abc()↓-> Int {}"): Example("func abc() -> Int {}"),
            Example("func abc()↓ ->Int {}"): Example("func abc() -> Int {}"),
            Example("func abc()↓  ->  Int {}"): Example("func abc() -> Int {}"),
            Example("func abc()\n  ↓->  Int {}"): Example("func abc()\n  -> Int {}"),
            Example("func abc()\n ↓->  Int {}"): Example("func abc()\n -> Int {}"),
            Example("func abc()↓  ->\n  Int {}"): Example("func abc() ->\n  Int {}"),
            Example("func abc()↓  ->\nInt {}"): Example("func abc() ->\nInt {}"),
        ]
    )
}

private extension ReturnArrowWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionTypeSyntax) {
            if let violation = node.returnClause.arrow.arrowViolation {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: FunctionSignatureSyntax) {
            if let output = node.returnClause, let violation = output.arrow.arrowViolation {
                violations.append(violation)
            }
        }

        override func visitPost(_ node: ClosureSignatureSyntax) {
            if let output = node.returnClause, let violation = output.arrow.arrowViolation {
                violations.append(violation)
            }
        }
    }
}

private extension TokenSyntax {
    var arrowViolation: ReasonedRuleViolation? {
        guard let previousToken = previousToken(viewMode: .sourceAccurate),
              let nextToken = nextToken(viewMode: .sourceAccurate) else {
            return nil
        }

        var start: AbsolutePosition?
        var end: AbsolutePosition?
        var correction = " -> "

        if previousToken.trailingTrivia != .space && !leadingTrivia.containsNewlines() {
            start = previousToken.endPositionBeforeTrailingTrivia
            end = endPosition

            if nextToken.leadingTrivia.containsNewlines() {
                correction = " ->"
            }
        }

        if trailingTrivia != .space && !nextToken.leadingTrivia.containsNewlines() {
            if leadingTrivia.containsNewlines() {
                start = positionAfterSkippingLeadingTrivia
                correction = "-> "
            } else {
                start = previousToken.endPositionBeforeTrailingTrivia
            }
            end = endPosition
        }

        guard let start, let end else {
            return nil
        }

        return .init(position: start, correction: .init(start: start, end: end, replacement: correction))
    }
}
