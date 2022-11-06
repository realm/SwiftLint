import SwiftSyntax

struct VerticalParameterAlignmentRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "vertical_parameter_alignment",
        name: "Vertical Parameter Alignment",
        description: "Function parameters should be aligned vertically if they're in multiple lines in a declaration",
        kind: .style,
        nonTriggeringExamples: VerticalParameterAlignmentRuleExamples.nonTriggeringExamples,
        triggeringExamples: VerticalParameterAlignmentRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(locationConverter: file.locationConverter)
    }
}

private extension VerticalParameterAlignmentRule {
    final class Visitor: ViolationsSyntaxVisitor {
        private let locationConverter: SourceLocationConverter

        init(locationConverter: SourceLocationConverter) {
            self.locationConverter = locationConverter
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            violations.append(contentsOf: violations(for: node.signature.input.parameterList))
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            violations.append(contentsOf: violations(for: node.signature.input.parameterList))
        }

        private func violations(for params: FunctionParameterListSyntax) -> [AbsolutePosition] {
            guard params.count > 1 else {
                return []
            }

            let paramLocations = params.compactMap { param -> (position: AbsolutePosition, line: Int, column: Int)? in
                let position = param.positionAfterSkippingLeadingTrivia
                let location = locationConverter.location(for: position)
                guard let line = location.line, let column = location.column else {
                    return nil
                }
                return (position, line, column)
            }

            guard let firstParamLoc = paramLocations.first else { return [] }

            var violations: [AbsolutePosition] = []
            for (index, paramLoc) in paramLocations.enumerated() where index > 0 && paramLoc.line > firstParamLoc.line {
                let previousParamLoc = paramLocations[index - 1]
                if previousParamLoc.line < paramLoc.line && firstParamLoc.column != paramLoc.column {
                    violations.append(paramLoc.position)
                }
            }

            return violations
        }
    }
}
