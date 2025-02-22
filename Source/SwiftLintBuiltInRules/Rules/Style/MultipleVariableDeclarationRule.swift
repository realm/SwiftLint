import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct MultipleVariableDeclarationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "multiple_variable_declaration",
        name: "Multiple Variable Declaration",
        description: "Variables should not be declared on the same line",
        kind: .style,
        nonTriggeringExamples: [
            Example(
                """
                    let a = 1
                    let b = 2
                """
                ),
            Example(
                """
                    var x = 10
                    var y = 20
                """
            ),
            Example(
                """
                    let x = 10
                    var y = 20
                """
            ),
        ],
        triggeringExamples: [
            Example("let a = 1; let b = 2"),
            Example("var x = 10; var y = 20"),
            Example("let x = 10; var y = 20"),
        ]
    )
}

private extension MultipleVariableDeclarationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var lastVariableLine: Int?

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            let converter = file.locationConverter
            let currentLocation = converter
                .location(for: node.positionAfterSkippingLeadingTrivia)
            let currentLine = currentLocation.line
            guard currentLine > 0 else {
                return .skipChildren
            }

            if let lastLine = lastVariableLine, lastLine == currentLine {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            lastVariableLine = currentLine
            return .visitChildren
        }
    }
}
