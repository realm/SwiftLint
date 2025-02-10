import SwiftLintCore
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
            Example("let a = 1\nlet b = 2"),
            Example("var x = 10\nvar y = 20"),
        ],
        triggeringExamples: [
            Example("let a = 1; let b = 2"),
            Example("var x = 10; var y = 20"),
        ]
    )

    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private var lastVariableLine: Int?

        override func visitPost(_ node: CodeBlockItemSyntax) {
            let converter = file.locationConverter
            let currentLocation = converter
                .location(for: node.positionAfterSkippingLeadingTrivia)
            let currentLine = currentLocation.line
            guard currentLine > 0 else {
                return
            }

            if let lastLine = lastVariableLine, lastLine == currentLine {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            lastVariableLine = currentLine
        }
    }
}
