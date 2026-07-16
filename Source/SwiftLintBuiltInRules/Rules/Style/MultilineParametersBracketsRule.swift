import SourceKittenFramework
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
        nonTriggeringExamples: #examples([
            """
            func foo(param1: String, param2: String, param3: String)
            """,
            """
            func foo(
                param1: String, param2: String, param3: String
            )
            """,
            """
            func foo(
                param1: String,
                param2: String,
                param3: String
            )
            """,
            """
            class SomeType {
                func foo(param1: String, param2: String, param3: String)
            }
            """,
            """
            class SomeType {
                func foo(
                    param1: String, param2: String, param3: String
                )
            }
            """,
            """
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String
                )
            }
            """,
            """
            func foo<T>(param1: T, param2: String, param3: String) -> T { /* some code */ }
            """,
            """
                func foo(a: [Int] = [
                    1
                ])
            """,
        ]),
        triggeringExamples: #examples([
            """
            func foo(↓param1: String, param2: String,
                     param3: String
            )
            """,
            """
            func foo(
                param1: String,
                param2: String,
                param3: String↓)
            """,
            """
            class SomeType {
                func foo(↓param1: String, param2: String,
                         param3: String
                )
            }
            """,
            """
            class SomeType {
                func foo(
                    param1: String,
                    param2: String,
                    param3: String↓)
            }
            """,
            """
            func foo<T>(↓param1: T, param2: String,
                     param3: String
            ) -> T
            """,
        ])
    )
}

private extension MultilineParametersBracketsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionDeclSyntax) {
            validate(
                nameStart: node.name.positionAfterSkippingLeadingTrivia,
                parameterClause: node.signature.parameterClause
            )
        }

        override func visitPost(_ node: InitializerDeclSyntax) {
            validate(
                nameStart: node.initKeyword.positionAfterSkippingLeadingTrivia,
                parameterClause: node.signature.parameterClause
            )
        }

        override func visitPost(_ node: SubscriptDeclSyntax) {
            validate(
                nameStart: node.subscriptKeyword.positionAfterSkippingLeadingTrivia,
                parameterClause: node.parameterClause
            )
        }

        private func validate(nameStart: AbsolutePosition, parameterClause: FunctionParameterClauseSyntax) {
            let parameters = parameterClause.parameters
            guard
                parameters.isNotEmpty,
                let declaration = text(
                    from: nameStart,
                    to: parameterClause.rightParen.endPositionBeforeTrailingTrivia
                )
            else {
                return
            }

            // Ranges spanning each parameter from the first token after its attributes to the end of its
            // type, ellipsis or default value, excluding any trailing comma.
            let parameterRanges = parameters.map { parameter in
                (start: startPosition(of: parameter), end: endPosition(of: parameter))
            }

            let parametersNewlineCount = parameterRanges.compactMap { range in
                text(from: range.start, to: range.end)?.countOccurrences(of: "\n")
            }.reduce(0, +)
            let declarationNewlineCount = declaration.countOccurrences(of: "\n")
            let isMultiline = declarationNewlineCount > parametersNewlineCount

            guard isMultiline else {
                return
            }

            let openingBracketEnd = parameterClause.leftParen.endPositionBeforeTrailingTrivia
            if let firstParameterRange = parameterRanges.first,
               containsOnlySpacesOrTabs(from: openingBracketEnd, to: firstParameterRange.start) {
                violations.append(openingBracketEnd)
            }

            let closingBracketStart = parameterClause.rightParen.positionAfterSkippingLeadingTrivia
            if let lastParameterRange = parameterRanges.last,
               containsOnlySpacesOrTabs(from: lastParameterRange.end, to: closingBracketStart) {
                violations.append(closingBracketStart)
            }
        }

        private func startPosition(of parameter: FunctionParameterSyntax) -> AbsolutePosition {
            parameter.modifiers.first?.positionAfterSkippingLeadingTrivia
                ?? parameter.firstName.positionAfterSkippingLeadingTrivia
        }

        private func endPosition(of parameter: FunctionParameterSyntax) -> AbsolutePosition {
            if let defaultValue = parameter.defaultValue {
                return defaultValue.endPositionBeforeTrailingTrivia
            }
            if let ellipsis = parameter.ellipsis {
                return ellipsis.endPositionBeforeTrailingTrivia
            }
            return parameter.type.endPositionBeforeTrailingTrivia
        }

        private func containsOnlySpacesOrTabs(from start: AbsolutePosition, to end: AbsolutePosition) -> Bool {
            guard let gap = text(from: start, to: end) else {
                return false
            }
            return gap.allSatisfy { $0 == " " || $0 == "\t" }
        }

        private func text(from start: AbsolutePosition, to end: AbsolutePosition) -> String? {
            let byteRange = ByteRange(
                location: ByteCount(start),
                length: ByteCount(end.utf8Offset - start.utf8Offset)
            )
            return file.stringView.substringWithByteRange(byteRange)
        }
    }
}
