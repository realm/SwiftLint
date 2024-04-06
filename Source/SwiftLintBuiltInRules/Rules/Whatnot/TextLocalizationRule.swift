import SwiftLintCore
import SwiftSyntax

struct TextLocalizationRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "text_localization",
        name: "SwiftUI.Text Localization",
        description: "Avoid using SwiftUI.Text.init with string literals",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                let string = ""
                Text(string)
            """),
            Example("""
                Text(string)
            """),
            Example("""
                Text(verbatim: "blah")
            """)
        ],
        triggeringExamples: [
            Example("""
                ↓Text("blah")
            """),
            Example("""
                ↓Text("blah", comment: "A nice comment")
            """),
            Example("""
                ↓Text("blah", bundle: .module, comment: "A nice comment")
            """),
            // String interpolation
            Example(#"↓Text("foo \(blah) bar")"#)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

private extension TextLocalizationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if isInvalidTextInitializer(node) {
                violations.append(reason(position: node.positionAfterSkippingLeadingTrivia))
            }
        }
    }
}

private extension TextLocalizationRule.Visitor {
    func isInvalidTextInitializer(_ node: FunctionCallExprSyntax) -> Bool {
        guard let declRef = node.calledExpression.as(DeclReferenceExprSyntax.self) else { return false }
        let isTextInit = declRef.baseName.text == "Text"
        let firstArgument = node.arguments.first
        let isVerbatimFirstArgumentLabel = firstArgument?.label?.text == "verbatim"
        let isUntrustedMarkdownFirstArgumentLabel = firstArgument?.label?.text == "untrustedMarkdown"
        let hasStringLiteralFirstArgument = firstArgument?.expression.as(StringLiteralExprSyntax.self) != nil

        return isTextInit
            && hasStringLiteralFirstArgument
            && !isVerbatimFirstArgumentLabel
            && !isUntrustedMarkdownFirstArgumentLabel
    }
}

private extension TextLocalizationRule.Visitor {
    func reason(position: AbsolutePosition) -> ReasonedRuleViolation {
        .init(
            position: position,
            reason: """
            Avoid calling Text.init with string literals. \
            Use String.init if this string should be translated, otherwise use Text.init(verbatim:)
            """,
            severity: .warning
        )
    }
}

// TODO: Picker
