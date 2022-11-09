import SwiftSyntax

struct MultilineParametersRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = MultilineParametersConfiguration()

    init() {}

    static let description = RuleDescription(
        identifier: "multiline_parameters",
        name: "Multiline Parameters",
        description: "Functions and methods parameters should be either on the same line, or one per line.",
        kind: .style,
        nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineParametersRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(allowsSingleLine: configuration.allowsSingleLine, locationConverter: file.locationConverter)
    }
}

private extension MultilineParametersRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let allowsSingleLine: Bool
        private let locationConverter: SourceLocationConverter

        init(allowsSingleLine: Bool, locationConverter: SourceLocationConverter) {
            self.allowsSingleLine = allowsSingleLine
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            if containsViolation(for: node.signature) {
                violations.append(node.identifier.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            if containsViolation(for: node.signature) {
                violations.append(node.initKeyword.positionAfterSkippingLeadingTrivia)
            }
        }

        private func containsViolation(for signature: FunctionSignatureSyntax) -> Bool {
            let parameterPositions = signature.input.parameterList.map(\.positionAfterSkippingLeadingTrivia)
            guard parameterPositions.isNotEmpty else {
                return false
            }

            var numberOfParameters = 0
            var linesWithParameters = Set<Int>()

            for position in parameterPositions {
                guard let line = locationConverter.location(for: position).line else {
                    continue
                }

                linesWithParameters.insert(line)
                numberOfParameters += 1
            }

            guard linesWithParameters.count > (allowsSingleLine ? 1 : 0),
                  numberOfParameters != linesWithParameters.count else {
                return false
            }

            return true
        }
    }
}
