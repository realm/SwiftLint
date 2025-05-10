import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineArgumentsRule: Rule {
    var configuration = MultilineArgumentsConfiguration()

    static let description = RuleDescription(
        identifier: "multiline_arguments",
        name: "Multiline Arguments",
        description: "Arguments should be either on the same line, or one per line",
        kind: .style,
        nonTriggeringExamples: MultilineArgumentsRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineArgumentsRuleExamples.triggeringExamples
    )
}

private extension MultilineArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.arguments.count > 1 else {
                return
            }

            let functionCallPosition = node.calledExpression.positionAfterSkippingLeadingTrivia
            let functionCallLine = locationConverter.location(for: functionCallPosition).line
            let wrappedArguments: [Argument] = node.arguments
                .enumerated()
                .compactMap { idx, argument in
                    Argument(element: argument, locationConverter: locationConverter, index: idx)
                }

            var violatingArguments = findViolations(in: wrappedArguments, functionCallLine: functionCallLine)

            if configuration.onlyEnforceAfterFirstClosureOnFirstLine {
                violatingArguments = removeViolationsBeforeFirstClosure(arguments: wrappedArguments,
                                                                        violations: violatingArguments)
            }

            violations.append(contentsOf: violatingArguments.map(\.offset))
        }

        // MARK: - Violation Logic

        private func findViolations(in arguments: [Argument],
                                    functionCallLine: Int) -> [Argument] {
            var visitedLines = Set<Int>()

            if configuration.firstArgumentLocation == .sameLine {
                visitedLines.insert(functionCallLine)
            }

            let violations = arguments.compactMap { argument -> Argument? in
                let (line, idx) = (argument.line, argument.index)
                let (firstVisit, _) = visitedLines.insert(line)

                if idx == 0 {
                    switch configuration.firstArgumentLocation {
                    case .anyLine: return nil
                    case .nextLine: return line > functionCallLine ? nil : argument
                    case .sameLine: return line > functionCallLine ? argument : nil
                    }
                } else {
                    return firstVisit ? nil : argument
                }
            }

            // only report violations if multiline
            return visitedLines.count > 1 ? violations : []
        }

        private func removeViolationsBeforeFirstClosure(arguments: [Argument],
                                                        violations: [Argument]) -> [Argument] {
            guard let firstClosure = arguments.first(where: \.isClosure),
                  let firstArgument = arguments.first else {
                return violations
            }

            let violationSlice: ArraySlice<Argument> = violations
                .drop { argument in
                    // drop violations if they precede the first closure,
                    // if that closure is in the first line
                    firstArgument.line == firstClosure.line &&
                    argument.line == firstClosure.line &&
                    argument.index <= firstClosure.index
                }

            return Array(violationSlice)
        }
    }
}

private struct Argument {
    let offset: AbsolutePosition
    let line: Int
    let index: Int
    let expression: ExprSyntax

    init?(element: LabeledExprSyntax, locationConverter: SourceLocationConverter, index: Int) {
        self.offset = element.positionAfterSkippingLeadingTrivia
        self.line = locationConverter.location(for: offset).line
        self.index = index
        self.expression = element.expression
    }

    var isClosure: Bool {
        expression.is(ClosureExprSyntax.self)
    }
}
