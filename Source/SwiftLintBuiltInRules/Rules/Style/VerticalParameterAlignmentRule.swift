import SwiftSyntax

@SwiftSyntaxRule
struct VerticalParameterAlignmentRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "vertical_parameter_alignment",
        name: "Vertical Parameter Alignment",
        description: "Function parameters should be aligned vertically if they're in multiple lines in a declaration",
        kind: .style,
        nonTriggeringExamples: VerticalParameterAlignmentRuleExamples.nonTriggeringExamples,
        triggeringExamples: VerticalParameterAlignmentRuleExamples.triggeringExamples
    )
}

private extension VerticalParameterAlignmentRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        // Computed once per file: `SourceLocationConverter.sourceLines` materializes every line of the
        // file as a new `[String]` on each access.
        private lazy var sourceLines = locationConverter.sourceLines

        override func visitPost(_ node: FunctionDeclSyntax) {
            violations.append(contentsOf: violations(for: node.signature.parameterClause.parameters))
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            violations.append(contentsOf: violations(for: node.signature.parameterClause.parameters))
        }

        private func violations(for params: FunctionParameterListSyntax) -> [AbsolutePosition] {
            guard params.count > 1 else {
                return []
            }

            let paramLocations = params.map { param -> (position: AbsolutePosition, line: Int, column: Int) in
                let position = param.positionAfterSkippingLeadingTrivia
                let location = locationConverter.location(for: position)
                return (position, location.line, location.column)
            }

            guard let firstParamLoc = paramLocations.first else { return [] }

            var violations: [AbsolutePosition] = []
            // Grapheme columns are only needed for parameters that are actually compared, i.e. the first
            // parameter and parameters starting a new line. Computing them lazily avoids touching the
            // source lines at all for the common single-line declaration.
            var firstParamColumn: Int?
            for (index, paramLoc) in paramLocations.enumerated() where index > 0 && paramLoc.line > firstParamLoc.line {
                let previousParamLoc = paramLocations[index - 1]
                if previousParamLoc.line < paramLoc.line {
                    let firstColumn = firstParamColumn
                        ?? graphemeColumn(line: firstParamLoc.line, column: firstParamLoc.column)
                    firstParamColumn = firstColumn
                    if firstColumn != graphemeColumn(line: paramLoc.line, column: paramLoc.column) {
                        violations.append(paramLoc.position)
                    }
                }
            }

            return violations
        }

        /// Converts a UTF-8 byte column into a column counted in grapheme clusters, so that parameters preceded
        /// by multi-byte characters (e.g. a non-ASCII function name) are compared by their visible alignment
        /// rather than by their byte offset.
        private func graphemeColumn(line: Int, column: Int) -> Int {
            guard let graphemeClusters = String(sourceLines[line - 1].utf8.prefix(column - 1)) else {
                return column
            }
            return graphemeClusters.count + 1
        }
    }
}
