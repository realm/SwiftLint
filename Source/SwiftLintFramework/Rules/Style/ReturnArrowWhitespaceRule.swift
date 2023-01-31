import Foundation
import SwiftSyntax

struct ReturnArrowWhitespaceRule: SwiftSyntaxRule, CorrectableRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "return_arrow_whitespace",
        name: "Returning Whitespace",
        description: "Return arrow and return type should be separated by a single space or on a " +
                     "separate line",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc() -> Int {}\n"),
            Example("func abc() -> [Int] {}\n"),
            Example("func abc() -> (Int, Int) {}\n"),
            Example("var abc = {(param: Int) -> Void in }\n"),
            Example("func abc() ->\n    Int {}\n"),
            Example("func abc()\n    -> Int {}\n"),
            Example("""
            func reallyLongFunctionMethods<T>(withParam1: Int, param2: String, param3: Bool) where T: AGenericConstraint
                -> Int {
                return 1
            }
            """),
            Example("typealias SuccessBlock = ((Data) -> Void)")
        ],
        triggeringExamples: [
            Example("func abc()↓->Int {}\n"),
            Example("func abc()↓->[Int] {}\n"),
            Example("func abc()↓->(Int, Int) {}\n"),
            Example("func abc()↓-> Int {}\n"),
            Example("func abc()↓->   Int {}\n"),
            Example("func abc()↓ ->Int {}\n"),
            Example("func abc()↓  ->  Int {}\n"),
            Example("var abc = {(param: Int)↓ ->Bool in }\n"),
            Example("var abc = {(param: Int)↓->Bool in }\n"),
            Example("typealias SuccessBlock = ((Data)↓->Void)"),
            Example("func abc()\n  ↓->  Int {}\n"),
            Example("func abc()\n ↓->  Int {}\n"),
            Example("func abc()↓  ->\n  Int {}\n"),
            Example("func abc()↓  ->\nInt {}\n")
        ],
        corrections: [
            Example("func abc()↓->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓-> Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓ ->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓  ->  Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()\n  ↓->  Int {}\n"): Example("func abc()\n  -> Int {}\n"),
            Example("func abc()\n ↓->  Int {}\n"): Example("func abc()\n -> Int {}\n"),
            Example("func abc()↓  ->\n  Int {}\n"): Example("func abc() ->\n  Int {}\n"),
            Example("func abc()↓  ->\nInt {}\n"): Example("func abc() ->\nInt {}\n")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        let violations = Visitor(viewMode: .sourceAccurate)
            .walk(file: file, handler: \.corrections)
            .compactMap { violation in
                file.stringView.NSRange(start: violation.start, end: violation.end).map { range in
                    (range: range, correction: violation.correction)
                }
            }
            .filter {
                file.ruleEnabled(violatingRange: $0.range, for: self) != nil
            }

        guard violations.isNotEmpty else { return [] }

        let description = Self.description
        var corrections = [Correction]()
        var contents = file.contents
        for violation in violations.sorted(by: { $0.range.location > $1.range.location }) {
            let contentsNSString = contents.bridge()
            contents = contentsNSString.replacingCharacters(in: violation.range, with: violation.correction)
            let location = Location(file: file, characterOffset: violation.range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}

private extension ReturnArrowWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private(set) var corrections: [ArrowViolation] = []

        override func visitPost(_ node: FunctionTypeSyntax) {
            guard let violation = node.arrow.arrowViolation else {
                return
            }

            violations.append(violation.start)
            corrections.append(violation)
        }

        override func visitPost(_ node: FunctionSignatureSyntax) {
            guard let output = node.output, let violation = output.arrow.arrowViolation else {
                return
            }

            violations.append(violation.start)
            corrections.append(violation)
        }

        override func visitPost(_ node: ClosureSignatureSyntax) {
            guard let output = node.output, let violation = output.arrow.arrowViolation else {
                return
            }

            violations.append(violation.start)
            corrections.append(violation)
        }
    }
}

private struct ArrowViolation {
    let start: AbsolutePosition
    let end: AbsolutePosition
    let correction: String
}

private extension TokenSyntax {
    var arrowViolation: ArrowViolation? {
        guard let previousToken, let nextToken else {
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

        return ArrowViolation(start: start, end: end, correction: correction)
    }
}
