import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineParametersRule: Rule {
    var configuration = MultilineParametersConfiguration()

    static let description = RuleDescription(
        identifier: "multiline_parameters",
        name: "Multiline Parameters",
        description: """
            Functions, initializers, and function call arguments should be either on the same line, or one per line
            """,
        kind: .style,
        nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineParametersRuleExamples.triggeringExamples
    )
}

private extension MultilineParametersRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            if containsViolation(for: node.signature) {
                violations.append(node.name.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if containsViolation(for: node.signature) {
                violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.arguments.isNotEmpty else { return }
            guard configuration.checkCalls else { return }
            guard node.trailingClosure == nil else { return }

            if containsViolation(for: node.arguments) {
                let anchor = node.calledExpression.positionAfterSkippingLeadingTrivia
                violations.append(anchor)
            }
        }

        private func containsViolation(for signature: FunctionSignatureSyntax) -> Bool {
            let parameterPositions = signature.parameterClause.parameters.map(\.positionAfterSkippingLeadingTrivia)
            return containsViolation(parameterPositions: parameterPositions)
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
