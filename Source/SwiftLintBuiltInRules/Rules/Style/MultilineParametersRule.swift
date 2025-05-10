import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineParametersRule: Rule {
    var configuration = MultilineParametersConfiguration()

    static let description = RuleDescription(
        identifier: "multiline_parameters",
        name: "Multiline Parameters",
        description: "Functions and methods parameters should be either on the same line, or one per line",
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

        private func containsViolation(for signature: FunctionSignatureSyntax) -> Bool {
            let parameterPositions = signature.parameterClause.parameters.map(\.positionAfterSkippingLeadingTrivia)
            guard parameterPositions.isNotEmpty else {
                return false
            }

            var numberOfParameters = 0
            var linesWithParameters = Set<Int>()

            for position in parameterPositions {
                let line = locationConverter.location(for: position).line
                linesWithParameters.insert(line)
                numberOfParameters += 1
            }

            if let maxNumberOfSingleLineParameters = configuration.maxNumberOfSingleLineParameters,
               configuration.allowsSingleLine,
               numberOfParameters > maxNumberOfSingleLineParameters {
                return true
            }

            guard linesWithParameters.count > (configuration.allowsSingleLine ? 1 : 0),
                  numberOfParameters != linesWithParameters.count else {
                return false
            }

            return true
        }
    }
}
