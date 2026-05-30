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

            let paramLocations = params.compactMap { param -> (position: AbsolutePosition, line: Int, column: Int)? in
                let position = param.positionAfterSkippingLeadingTrivia
                let location = locationConverter.location(for: position)
                return (position, location.line, location.column)
            }

            guard let firstParamLoc = paramLocations.first else { return [] }

            let firstParamCharacterColumn = characterColumn(
                onLine: firstParamLoc.line,
                utf8Column: firstParamLoc.column
            )

            var violations: [AbsolutePosition] = []
            for (index, paramLoc) in paramLocations.enumerated() where index > 0 && paramLoc.line > firstParamLoc.line {
                let previousParamLoc = paramLocations[index - 1]
                let paramCharacterColumn = characterColumn(onLine: paramLoc.line, utf8Column: paramLoc.column)
                if previousParamLoc.line < paramLoc.line,
                   firstParamCharacterColumn != paramCharacterColumn {
                    violations.append(paramLoc.position)
                }
            }

            return violations
        }

        private func characterColumn(onLine lineNumber: Int, utf8Column: Int) -> Int {
            let line = locationConverter.sourceLines[lineNumber - 1]
            guard utf8Column > 0 else { return 0 }

            let utf8Offset = utf8Column - 1
            var byteCount = 0
            var characterCount = 0

            for character in line {
                let characterUtf8Length = character.utf8.count
                if byteCount + characterUtf8Length > utf8Offset {
                    return characterCount
                }
                byteCount += characterUtf8Length
                characterCount += 1
            }

            return characterCount
        }
    }
}
