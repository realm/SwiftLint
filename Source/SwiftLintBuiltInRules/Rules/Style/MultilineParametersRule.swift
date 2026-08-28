import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(correctable: true, optIn: true)
struct MultilineParametersRule: Rule {
    var configuration = MultilineParametersConfiguration()

    enum Reason {
        static let singleLineMultipleParametersNotAllowed =
            "Single-line functions with multiple parameters are not allowed"

        static func tooManyParametersOnSingleLine(max: Int) -> String {
            "Too many parameters on a single line (max: \(max))"
        }

        static let eachParameterMustStartOnOwnLine =
            "In multi-line functions, each parameter must start on its own line"
    }

    static let description = RuleDescription(
        identifier: "multiline_parameters",
        name: "Multiline Parameters",
        description: "Functions and methods parameters should be either on the same line, or one per line",
        kind: .style,
        nonTriggeringExamples: MultilineParametersRuleExamples.nonTriggeringExamples,
        triggeringExamples: MultilineParametersRuleExamples.triggeringExamples,
        corrections: MultilineParametersRuleExamples.corrections
    )
}

private extension MultilineParametersRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var lineCache: [Int: Int] = [:]

        override init(configuration: ConfigurationType, file: SwiftLintFile) {
            super.init(configuration: configuration, file: file)
            lineCache.reserveCapacity(64)
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            violations.append(
                contentsOf: violations(for: node.signature, declNode: node)
            )
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            violations.append(
                contentsOf: violations(for: node.signature, declNode: node)
            )
        }

        private func violations(
            for signature: FunctionSignatureSyntax,
            declNode: some SyntaxProtocol
        ) -> [ReasonedRuleViolation] {
            let parameters = Array(signature.parameterClause.parameters)
            guard parameters.count > 1 else { return [] }

            let parameterPositions = parameters.map(\.positionAfterSkippingLeadingTrivia)
            let firstLine = line(for: parameterPositions[0])
            let allOnSameLine = parameterPositions.allSatisfy { line(for: $0) == firstLine }

            if allOnSameLine {
                let correction = correctSingleLine(
                    parameters: parameters,
                    parameterClause: signature.parameterClause,
                    declNode: declNode
                )
                if !configuration.allowsSingleLine {
                    return [
                        ReasonedRuleViolation(
                            position: parameterPositions[1],
                            reason: Reason.singleLineMultipleParametersNotAllowed,
                            correction: correction
                        ),
                    ]
                }

                if let max = configuration.maxNumberOfSingleLineParameters,
                   parameterPositions.count > max {
                    return [
                        ReasonedRuleViolation(
                            position: parameterPositions[max],
                            reason: Reason.tooManyParametersOnSingleLine(max: max),
                            correction: correction
                        ),
                    ]
                }

                return []
            }

            return multilineViolations(
                parameters: parameters,
                parameterClause: signature.parameterClause,
                declNode: declNode
            )
        }

        private func multilineViolations(
            parameters: [FunctionParameterSyntax],
            parameterClause: FunctionParameterClauseSyntax,
            declNode: some SyntaxProtocol
        ) -> [ReasonedRuleViolation] {
            var result: [ReasonedRuleViolation] = []
            var correction = correctSingleLine(
                parameters: parameters,
                parameterClause: parameterClause,
                declNode: declNode
            )

            for index in parameters.indices.dropLast() {
                let current = parameters[index]
                let next = parameters[index + 1]
                let currentLine = line(for: current.positionAfterSkippingLeadingTrivia)
                let nextPosition = next.positionAfterSkippingLeadingTrivia
                let nextLine = line(for: nextPosition)

                if currentLine == nextLine {
                    result.append(
                        ReasonedRuleViolation(
                            position: nextPosition,
                            reason: Reason.eachParameterMustStartOnOwnLine,
                            correction: correction
                        )
                    )
                    correction = nil
                }
            }
            return result
        }

        private func normalizedText(parameter: FunctionParameterSyntax) -> String {
            parameter.description.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
        }

        private func correctSingleLine(
            parameters: [FunctionParameterSyntax],
            parameterClause: FunctionParameterClauseSyntax,
            declNode: some SyntaxProtocol
        ) -> ReasonedRuleViolation.ViolationCorrection? {
            guard
                let firstParameter = parameters.first,
                !parameters.contains(where: \.hasComments)
            else { return nil }

            let rightParen = parameterClause.rightParen

            let baseIndent = baseIndent(for: declNode)
            let indent = baseIndent + oneLevel

            let paramLines = parameters.enumerated().map { index, param -> String in
                let paramText = normalizedText(parameter: param)
                    .indent(by: oneLevel, skipFirst: true, skipEmptyLines: false)
                let needsComma = index < parameters.count - 1 && param.trailingComma?.presence == .missing
                return indent + paramText + (needsComma ? "," : "")
            }

            return ReasonedRuleViolation.ViolationCorrection(
                start: firstParameter.position,
                end: rightParen.endPositionBeforeTrailingTrivia,
                replacement: "\n" + (paramLines + [baseIndent + ")"]).joined(separator: "\n")
            )
        }

        private var indentationStyle: IndentationStyle {
            CurrentRule.configuration?.indentation ?? .default
        }

        private var oneLevel: String {
            indentationStyle.indentationString
        }

        private func baseIndent(for node: some SyntaxProtocol) -> String {
            let lineNumber = line(for: node.positionAfterSkippingLeadingTrivia)
            guard lineNumber > 0, lineNumber <= file.lines.count else { return "" }
            let rawIndent = String(file.lines[lineNumber - 1].content.prefix(while: { $0.isWhitespace && $0 != "\r" }))
            let style = indentationStyle
            return style.indentation(for: style.levelCount(in: rawIndent))
        }

        private func line(for position: AbsolutePosition) -> Int {
            let key = position.utf8Offset
            if let cached = lineCache[key] { return cached }
            let line = locationConverter.location(for: position).line
            lineCache[key] = line
            return line
        }
    }
}

private extension FunctionParameterSyntax {
    var hasComments: Bool {
        tokens(viewMode: .sourceAccurate).contains { token in
            token.leadingTrivia.containsComments || token.trailingTrivia.containsComments
        }
    }
}
