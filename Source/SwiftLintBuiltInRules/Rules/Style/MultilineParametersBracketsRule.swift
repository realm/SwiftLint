import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultilineParametersBracketsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "multiline_parameters_brackets",
        name: "Multiline Parameters Brackets",
        description: "Multiline parameters should have their surrounding brackets in a new line",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            func foo(param1: String, param2: String, param3: String)
            """),
            Example("""
            func foo(
                param1: String, param2: String, param3: String
            )
            """),
            Example("""
            func foo(
                param1: String,
                param2: String,
                param3: String
            )
            """),
            Example("""
            class SomeType {
                func foo(param1: String, param2: String, param3: String)
            }
            """),
            Example("""
            class SomeType {
                func foo(
                    param1: String, param2: String, param3: String
                )
            }
            """),
            Example("""
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String
                )
            }
            """),
            Example("""
            func foo<T>(param1: T, param2: String, param3: String) -> T { /* some code */ }
            """),
            Example("""
                func foo(a: [Int] = [
                    1
                ])
            """),
        ],
        triggeringExamples: [
            Example("""
            func foo(↓param1: String, param2: String,
                     param3: String
            )
            """),
            Example("""
            func foo(
                param1: String,
                param2: String,
                param3: String↓)
            """),
            Example("""
            class SomeType {
                func foo(↓param1: String, param2: String,
                         param3: String
                )
            }
            """),
            Example("""
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String↓)
            }
            """),
            Example("""
            func foo<T>(↓param1: T, param2: String,
                     param3: String
            ) -> T
            """),
        ]
    )
}

private extension MultilineParametersBracketsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            checkViolations(for: node.signature.parameterClause)
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            checkViolations(for: node.signature.parameterClause)
        }

        private func significantStartToken(for parameter: FunctionParameterSyntax) -> TokenSyntax? {
            // The first name token (external or internal)
            if parameter.firstName.tokenKind == .wildcard, let secondName = parameter.secondName {
                return secondName
            }
            return parameter.firstName
        }

        private func significantEndToken(for parameter: FunctionParameterSyntax) -> TokenSyntax? {
            // End of ellipsis, or type, or name (in that order of preference)
            if let ellipsis = parameter.ellipsis {
                return ellipsis
            }
            // Type is not optional, so directly use it
            return parameter.type.lastToken(viewMode: .sourceAccurate) // Gets the very last token of the type
        }

        private func checkViolations(
            for parameterClause: FunctionParameterClauseSyntax
        ) {
            guard parameterClause.parameters.isNotEmpty else {
                return
            }

            let parameters = parameterClause.parameters
            let leftParen = parameterClause.leftParen
            let rightParen = parameterClause.rightParen

            let leftParenLine = locationConverter.location(for: leftParen.positionAfterSkippingLeadingTrivia).line
            let rightParenLine = locationConverter.location(for: rightParen.positionAfterSkippingLeadingTrivia).line

            guard let firstParam = parameters.first, let lastParam = parameters.last else { return }

            guard let firstParamStartToken = significantStartToken(for: firstParam),
                  let lastParamEndToken = significantEndToken(for: lastParam) else {
                return // Should not happen with valid parameters
            }

            let firstParamSignificantStartLine = locationConverter.location(
                for: firstParamStartToken.positionAfterSkippingLeadingTrivia
            ).line
            let lastParamSignificantEndLine = locationConverter.location(
                for: lastParamEndToken.endPositionBeforeTrailingTrivia
            ).line

            guard isStructurallyMultiline(
                parameters: parameters,
                firstParam: firstParam,
                firstParamStartLine: firstParamSignificantStartLine,
                lastParamEndLine: lastParamSignificantEndLine,
                leftParenLine: leftParenLine
            ) else {
                return // Not structurally multiline, so this rule doesn't apply.
            }

            // Check if opening paren has first parameter on same line
            if leftParenLine == firstParamSignificantStartLine {
                violations.append(
                    ReasonedRuleViolation(
                        position: firstParam.positionAfterSkippingLeadingTrivia,
                        reason: "Opening parenthesis should be on a separate line when using multiline parameters"
                    )
                )
            }

            // Check if closing paren is on same line as last parameter's significant part
            if rightParenLine == lastParamSignificantEndLine {
                violations.append(
                    ReasonedRuleViolation(
                        position: rightParen.positionAfterSkippingLeadingTrivia,
                        reason: "Closing parenthesis should be on a separate line when using multiline parameters"
                    )
                )
            }
        }

        private func isStructurallyMultiline(
            parameters: FunctionParameterListSyntax,
            firstParam: FunctionParameterSyntax,
            firstParamStartLine: Int,
            lastParamEndLine: Int,
            leftParenLine: Int
        ) -> Bool {
            // First check if parameters themselves span multiple lines
            if parameters.count > 1 && areParametersOnDifferentLines(parameters: parameters, firstParam: firstParam) {
                return true
            }

            // Also check if first parameter starts on a different line than opening paren
            if firstParamStartLine > leftParenLine {
                return true
            }

            // Also check if parameters span from opening to closing paren across lines
            if firstParamStartLine != lastParamEndLine {
                return true
            }

            return false
        }

        private func areParametersOnDifferentLines(
            parameters: FunctionParameterListSyntax,
            firstParam: FunctionParameterSyntax
        ) -> Bool {
            var previousParamSignificantEndLine = -1
            if let firstParamEndToken = significantEndToken(for: firstParam) {
                 previousParamSignificantEndLine = locationConverter.location(
                    for: firstParamEndToken.endPositionBeforeTrailingTrivia
                 ).line
            }

            for (index, parameter) in parameters.enumerated() {
                if index == 0 { continue } // Already used firstParam for initialization

                guard let currentParamStartToken = significantStartToken(for: parameter) else { continue }
                let currentParamSignificantStartLine = locationConverter.location(
                    for: currentParamStartToken.positionAfterSkippingLeadingTrivia
                ).line

                if currentParamSignificantStartLine > previousParamSignificantEndLine {
                    return true
                }

                if let currentParamEndToken = significantEndToken(for: parameter) {
                     previousParamSignificantEndLine = locationConverter.location(
                        for: currentParamEndToken.endPositionBeforeTrailingTrivia
                     ).line
                } else {
                    // If a parameter somehow doesn't have a significant end,
                    // fallback to its start line to avoid issues in comparison.
                    previousParamSignificantEndLine = currentParamSignificantStartLine
                }
            }
            return false
        }
    }
}
