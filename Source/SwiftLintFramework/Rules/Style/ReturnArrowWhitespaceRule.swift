import SwiftSyntax

public struct ReturnArrowWhitespaceRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
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
            Example("func abc() ↓->Int {}\n"),
            Example("func abc()  ↓->  Int {}\n"),
            Example("var abc = {(param: Int) ↓->Bool in }\n"),
            Example("var abc = {(param: Int)↓->Bool in }\n"),
            Example("typealias SuccessBlock = ((Data)↓->Void)"),
            Example("func abc()\n  ↓->  Int {}\n"),
            Example("func abc()\n ↓->  Int {}\n"),
            Example("func abc()  ↓->\n  Int {}\n"),
            Example("func abc()  ↓->\nInt {}\n")
        ]/*,
        corrections: [
            Example("func abc()↓->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()↓-> Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc() ↓->Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()  ↓->  Int {}\n"): Example("func abc() -> Int {}\n"),
            Example("func abc()\n  ↓->  Int {}\n"): Example("func abc()\n  -> Int {}\n"),
            Example("func abc()\n ↓->  Int {}\n"): Example("func abc()\n-> Int {}\n"),
            Example("func abc()  ↓->\n  Int {}\n"): Example("func abc() ->\n  Int {}\n"),
            Example("func abc()  ↓->\nInt {}\n"): Example("func abc() ->\nInt {}\n")
        ]*/
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        nil
    }
}

private extension ReturnArrowWhitespaceRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionTypeSyntax) {
            guard node.arrow.hasArrowViolation else {
                return
            }

            violations.append(node.arrow.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: FunctionSignatureSyntax) {
            guard let output = node.output, output.arrow.hasArrowViolation else {
                return
            }

            violations.append(output.arrow.positionAfterSkippingLeadingTrivia)
        }

        override func visitPost(_ node: ClosureSignatureSyntax) {
            guard let output = node.output, output.arrow.hasArrowViolation else {
                return
            }

            violations.append(output.arrow.positionAfterSkippingLeadingTrivia)
        }
    }

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
            guard case let violations = node.arrow.arrowViolations,
                  violations.isNotEmpty,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(node.arrow.positionAfterSkippingLeadingTrivia)

            var newNode = node
            for violation in violations {
                switch violation {
                case .afterArrow:
                    newNode = newNode.withArrow(
                        node.arrow.withTrailingTrivia(.space)
                    )
                case .beforeArrow:
                    break
                }
            }

            return super.visit(newNode)
        }

        override func visit(_ node: FunctionSignatureSyntax) -> Syntax {
            guard let output = node.output,
                  case let violations = output.arrow.arrowViolations,
                  violations.isNotEmpty,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(output.arrow.positionAfterSkippingLeadingTrivia)

            var newNode = node
            for violation in violations {
                switch violation {
                case .afterArrow:
                    newNode = newNode
                        .withOutput(
                            output.withArrow(
                                output.arrow.withTrailingTrivia(.space)
                            )
                        )
                case .beforeArrow:
                    break
                }
            }

            return super.visit(newNode)
        }

        override func visit(_ node: ClosureSignatureSyntax) -> Syntax {
            guard let output = node.output,
                  case let violations = output.arrow.arrowViolations,
                  violations.isNotEmpty,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(output.arrow.positionAfterSkippingLeadingTrivia)

            var newNode = node
            for violation in violations {
                switch violation {
                case .afterArrow:
                    newNode = newNode
                        .withOutput(
                            output.withArrow(
                                output.arrow.withTrailingTrivia(.space)
                            )
                        )
                case .beforeArrow:
                    break
                }
            }

            return super.visit(newNode)
        }
    }
}

private enum SpacingViolationKind {
    case beforeArrow
    case afterArrow
}

private extension TokenSyntax {
    var hasArrowViolation: Bool {
        arrowViolations.isNotEmpty
    }

    var arrowViolations: [SpacingViolationKind] {
        guard let previousToken = previousToken, let nextToken = nextToken else {
            return []
        }

        var violations: [SpacingViolationKind] = []
        if previousToken.trailingTrivia != .space && !leadingTrivia.containsNewlines() {
            violations.append(.beforeArrow)
        }

        if trailingTrivia != .space && !nextToken.leadingTrivia.containsNewlines() {
            violations.append(.afterArrow)
        }

        return violations
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
