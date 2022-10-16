import SwiftSyntax

public struct ReturnArrowWhitespaceRule: SwiftSyntaxRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "return_arrow_whitespace",
        name: "Returning Whitespace",
        description: "Return arrow and return type should be separated by a single space or on a " +
                     "separate line.",
        kind: .style,
        nonTriggeringExamples: [
            Example("func abc() -> Int {}\n"),
            Example("func abc() -> [Int] {}\n"),
            Example("func abc() -> (Int, Int) {}\n"),
            Example("var abc = {(param: Int) -> Void in }\n"),
            Example("func abc() ->\n    Int {}\n"),
            Example("func abc()\n    -> Int {}\n"),
            Example("typealias SuccessBlock = ((Data) -> Void)")
        ],
        triggeringExamples: [
            Example("func abc()↓->Int {}\n"),
            Example("func abc()↓->[Int] {}\n"),
            Example("func abc()↓->(Int, Int) {}\n"),
            Example("func abc()↓-> Int {}\n"),
            Example("func abc()↓ ->Int {}\n"),
            Example("func abc()↓  ->  Int {}\n"),
            Example("var abc = {(param: Int)↓ ->Bool in }\n"),
            Example("var abc = {(param: Int)↓->Bool in }\n"),
            Example("typealias SuccessBlock = ((Data)↓->Void)")
        ],
        corrections: [
            Example("func abc()↓->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓-> Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓ ->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓  ->  Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓\n  ->  Int {}\n"): Example("func abc()\n  -> Int {}\n"),
            Example("func abc()↓\n->  Int {}\n"): Example("func abc()\n-> Int {}\n"),
            Example("func abc()↓  ->\n  Int {}\n"): Example("func abc() ->\n  Int {}\n"),
            Example("func abc()↓  ->\nInt {}\n"): Example("func abc() ->\nInt {}\n")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor()
    }
}

private extension ReturnArrowWhitespaceRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: TokenSyntax) {
            guard node.hasArrowViolation else {
                return
            }

            violationPositions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }

}

private extension TokenSyntax {
    var hasArrowViolation: Bool {
        guard tokenKind == .arrow else {
            return false
        }

        if trailingTrivia.isEmpty {

        }
        return true
    }
    
}

private extension Trivia {
    func containsNewlines() -> Bool {
        contains { piece in
            if case .newlines = piece {
                return true
            } else {
                return false
            }
        }
    }
}
