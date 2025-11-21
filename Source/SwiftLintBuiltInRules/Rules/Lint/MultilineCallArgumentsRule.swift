import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineCallArgumentsRule: Rule {
    var configuration = MultilineCallArgumentsConfiguration()

    static let description = RuleDescription(
        identifier: "multiline_call_arguments",
        name: "Multiline Call Arguments",
        description: """
            Arguments in function and method calls should be either on the same line \
            or one per line when the call spans multiple lines
            """,
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
            Example("""
                    foo(param1: 1)
                    """,
                    configuration: [
                        "allows_single_line": false
                    ]),
            Example("""
                    Enum.foo(param1: 1)
                    """,
                    configuration: [
                        "allows_single_line": false
                    ]),
            Example("""
                    Enum.foo(param1: 1, param2: 2, param3: 3)
                    """,
                    configuration: [
                        "allows_single_line": true
                    ]),
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
            Example("""
                    ↓foo(param1: 1, param2: false)
                    """,
                    configuration: [
                        "allows_single_line": false
                    ]),
            Example("""
                    ↓Enum.foo(param1: 1, param2: false)
                    """,
                    configuration: [
                        "allows_single_line": false
                    ]),
        ]
    )
}

private extension MultilineCallArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.arguments.isNotEmpty else { return }
            guard node.trailingClosure == nil else { return }

            if containsViolation(for: node.arguments) {
                let anchor = node.calledExpression.positionAfterSkippingLeadingTrivia
                violations.append(anchor)
            }
        }

        private func containsViolation(for arguments: LabeledExprListSyntax) -> Bool {
            let argumentPositions = arguments.map(\.positionAfterSkippingLeadingTrivia)
            return containsViolation(parameterPositions: argumentPositions)
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
