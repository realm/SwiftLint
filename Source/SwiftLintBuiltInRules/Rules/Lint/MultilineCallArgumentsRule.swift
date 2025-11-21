import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineCallArgumentsRule: Rule {
    var configuration = MultilineCallArgumentsConfiguration()

    static let description = RuleDescription(
        identifier: "multiline_call_arguments",
        name: "Multiline Call Arguments",
        description: "Call should have one parameter per line",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
                    foo(
                    param1: "param1",
                        param2: false,
                        param3: []
                    )
                    """, configuration: ["max_number_of_single_line_parameters": 2]),
            Example("""
                    foo(param1: 1,
                        param2: false,
                        param3: [])
                    """, configuration: ["max_number_of_single_line_parameters": 1]),
            Example("foo(param1: 1, param2: false)",
                    configuration: ["max_number_of_single_line_parameters": 2]),
            Example("Enum.foo(param1: 1, param2: false)",
                    configuration: ["max_number_of_single_line_parameters": 2]),
            Example("foo(param1: 1)", configuration: ["allows_single_line": false]),
            Example("Enum.foo(param1: 1)", configuration: ["allows_single_line": false]),
            Example("Enum.foo(param1: 1, param2: 2, param3: 3)", configuration: ["allows_single_line": true]),
            Example("""
                    foo(
                        param1: 1,
                        param2: 2,
                        param3: 3
                    )
                    """,
                    configuration: [
                        "allows_single_line": false
                    ]),
        ],
        triggeringExamples: [
            Example("↓foo(param1: 1, param2: false, param3: [])",
                    configuration: [
                        "max_number_of_single_line_parameters": 2
                    ]),
            Example("↓Enum.foo(param1: 1, param2: false, param3: [])",
                    configuration: [
                        "max_number_of_single_line_parameters": 2
                    ]),
            Example("""
                    ↓foo(param1: 1, param2: false,
                         param3: [])
                    """, configuration: [
                        "max_number_of_single_line_parameters": 3
                    ]),
            Example("""
                    ↓Enum.foo(param1: 1, param2: false,
                         param3: [])
                    """, configuration: [
                        "max_number_of_single_line_parameters": 3
                    ]),
            Example("↓foo(param1: 1, param2: false)", configuration: ["allows_single_line": false]),
            Example("↓Enum.foo(param1: 1, param2: false)", configuration: ["allows_single_line": false]),
        ]
    )
}

private extension MultilineCallArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let parameterPositions = node.arguments.map(\.positionAfterSkippingLeadingTrivia)
            if containsViolation(parameterPositions: parameterPositions) {
                violations.append(node.calledExpression.positionAfterSkippingLeadingTrivia)
            }
        }

        private func containsViolation(parameterPositions: [AbsolutePosition]) -> Bool {
            guard parameterPositions.isNotEmpty else {
                return false
            }

            var numberOfParameters = 0
            var linesWithParameters: Set<Int> = []
            var hasMultipleParametersOnSameLine = false

            for position in parameterPositions {
                let line = locationConverter.location(for: position).line

                if !linesWithParameters.insert(line).inserted {
                    hasMultipleParametersOnSameLine = true
                }

                numberOfParameters += 1
            }

            if linesWithParameters.count == 1 {
                guard configuration.allowsSingleLine else {
                    return numberOfParameters > 1
                }

                if let maxNumberOfSingleLineParameters = configuration.maxNumberOfSingleLineParameters {
                    return numberOfParameters > maxNumberOfSingleLineParameters
                }

                return false
            }

            return hasMultipleParametersOnSameLine
        }
    }
}
