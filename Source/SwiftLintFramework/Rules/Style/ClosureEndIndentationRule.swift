import SwiftSyntax

public struct ClosureEndIndentationRule: SourceKitFreeRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_end_indentation",
        name: "Closure End Indentation",
        description: "Closure end should have the same indentation as the line that started it.",
        kind: .style,
        nonTriggeringExamples: ClosureEndIndentationRuleExamples.nonTriggeringExamples,
        triggeringExamples: ClosureEndIndentationRuleExamples.triggeringExamples
//        corrections: ClosureEndIndentationRuleExamples.corrections
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let visitor = makeVisitor(file: file) else {
            return []
        }

        return visitor
            .walk(file: file, handler: \.violations)
            .sorted(by: { $0.endPosition < $1.endPosition })
            .map { violation in
                styleViolation(for: violation, in: file)
            }
    }

    private func makeVisitor(file: SwiftLintFile) -> Visitor? {
        Visitor(locationConverter: file.locationConverter)
    }

    private func styleViolation(for violation: Violation, in file: SwiftLintFile) -> StyleViolation {
        let reason = "Closure end should have the same indentation as the line that started it. " +
                     "Expected \(violation.indentationRanges.expected), " +
                     "got \(violation.indentationRanges.actual)."

        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, position: violation.endPosition),
                              reason: reason)
    }
}

private extension ClosureEndIndentationRule {
    struct Violation {
        var indentationRanges: (expected: Int, actual: Int)
        var endPosition: AbsolutePosition
    }

    final class Visitor: SyntaxVisitor {
        private(set) var violations: [Violation] = []
        let locationConverter: SourceLocationConverter

        init(locationConverter: SourceLocationConverter) {
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: ClosureExprSyntax) {
            guard let violation = node.violation(locationConverter: locationConverter) else {
                return
            }

            violations.append(violation)
        }
    }
}

private extension ClosureExprSyntax {
    func violation(locationConverter: SourceLocationConverter) -> ClosureEndIndentationRule.Violation? {
        let startLocation = locationConverter.location(for: leftBrace.positionAfterSkippingLeadingTrivia)
        let endLocation = locationConverter.location(for: rightBrace.positionAfterSkippingLeadingTrivia)

        // only validate multi-line closures
        guard startLocation.line != endLocation.line else {
            return nil
        }

        guard let startLine = startLocation.line,
              let endColumn = endLocation.column,
              let firstTokenInLine = leftBrace.firstPreviousToken(inLine: startLine,
                                                                  locationConverter: locationConverter),
              case let firstTokenInLinePosition = firstTokenInLine.positionAfterSkippingLeadingTrivia,
              let firstTokenInLineColumn = locationConverter.location(for: firstTokenInLinePosition).column,
              firstTokenInLineColumn != endColumn else {
            return nil
        }

        return ClosureEndIndentationRule.Violation(
            indentationRanges: (expected: endColumn, actual: firstTokenInLineColumn),
            endPosition: rightBrace.positionAfterSkippingLeadingTrivia
        )
    }
}

private extension TokenSyntax {
    func firstPreviousToken(inLine line: Int, locationConverter: SourceLocationConverter) -> TokenSyntax? {
        guard let previousToken = self.previousToken else {
            return self
        }

        let location = locationConverter.location(for: previousToken.positionAfterSkippingLeadingTrivia)
        guard let previousTokenLine = location.line else {
            return nil
        }

        if previousTokenLine != line {
            return self
        }

        return previousToken.firstPreviousToken(inLine: line, locationConverter: locationConverter)
    }
}
