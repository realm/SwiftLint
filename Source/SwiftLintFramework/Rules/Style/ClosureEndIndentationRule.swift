import SwiftSyntax

public struct ClosureEndIndentationRule: SwiftSyntaxCorrectableRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: ClosureEndIndentationRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureEndIndentationRuleExamples.triggeringExamples,
        corrections: ClosureEndIndentationRuleExamples.corrections
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(locationConverter: file.locationConverter)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ClosureEndIndentationRule {
    struct Violation {
        let position: AbsolutePosition
        let expectedLeadingSpaces: Int
    }

    final class Visitor: ViolationsSyntaxVisitor {
        private let locationConverter: SourceLocationConverter

        init(locationConverter: SourceLocationConverter) {
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            if let violation = node.closureEndIndentationViolation(locationConverter: locationConverter) {
                violations.append(violation.position)
            }
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

        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            guard
                let violation = node.closureEndIndentationViolation(locationConverter: locationConverter),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            correctionPositions.append(violation.position)
            var rightBraceLeadingTrivia = Array(node.rightBrace.leadingTrivia)
            if case .spaces = rightBraceLeadingTrivia.last {
                rightBraceLeadingTrivia.removeLast()
            }

            rightBraceLeadingTrivia.append(.spaces(violation.expectedLeadingSpaces))
            let newTrivia = Trivia(pieces: rightBraceLeadingTrivia)
            let newRightBrace = node.rightBrace.withLeadingTrivia(newTrivia)
            let newNode = node.withRightBrace(newRightBrace)
            return super.visit(newNode)
        }
    }
}

private extension ClosureExprSyntax {
    func closureEndIndentationViolation(locationConverter: SourceLocationConverter)
        -> ClosureEndIndentationRule.Violation? {
        let leftBracePosition = leftBrace.positionAfterSkippingLeadingTrivia
        let leftBraceLocation = locationConverter.location(for: leftBracePosition)

        let rightBracePosition = rightBrace.positionAfterSkippingLeadingTrivia
        let rightBraceLocation = locationConverter.location(for: rightBracePosition)

        guard let startingLine = leftBraceLocation.line, startingLine != rightBraceLocation.line else {
            return nil
        }

        let startingLineContents = locationConverter.sourceLines[startingLine - 1]
        let startingLineLeadingWhitespace = startingLineContents.prefix(while: \.isWhitespace).count
        let startingLineColumn = startingLineLeadingWhitespace + 1

        if startingLineColumn != rightBraceLocation.column {
            return .init(position: rightBracePosition, expectedLeadingSpaces: startingLineLeadingWhitespace)
        } else {
            return nil
        }
    }
}
