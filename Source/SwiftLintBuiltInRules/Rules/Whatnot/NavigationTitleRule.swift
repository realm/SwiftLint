import SwiftLintCore
import SwiftSyntax

struct NavigationTitleRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "navigation_title_localization",
        name: "navigationTitle Localization",
        description: "Prevents incorrect usage of navigationTitle",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                .navigationTitle(myVariable)
            """),
            Example("""
                NavigationView {
                    Text(verbatim: "wow")
                }
                .navigationTitle(myVariable)
            """),
            Example("""
                NavigationView {
                    Text(verbatim: "wow")
                }
                .navigationTitle(verbatim: "title")
            """)
        ],
        triggeringExamples: [
            Example("""
                Text(wow).↓navigationTitle("title")
            """),
            Example("""
                NavigationView {
                    Text(verbatim: "wow")
                }
                .↓navigationTitle("title")
            """),
            Example("""
                NavigationView {
                    Text(verbatim: "wow")
                        .↓navigationTitle("title")
                }
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

private extension NavigationTitleRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let reason = invalidNavigationTitleViolation(node) {
                violations.append(reason)
            }
        }
    }
}

private extension NavigationTitleRule.Visitor {
    func invalidNavigationTitleViolation(_ node: FunctionCallExprSyntax) -> ReasonedRuleViolation? {
        guard let memberAccessRef = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccessRef.declName.baseName.text == "navigationTitle",
              let firstArgument = node.arguments.first else { return nil }

        let isVerbatimFirstArgumentLabel = firstArgument.label?.text == "verbatim"
        let hasStringLiteralFirstArgument = firstArgument.expression.as(StringLiteralExprSyntax.self) != nil

        if hasStringLiteralFirstArgument && !isVerbatimFirstArgumentLabel {
            return reason(
                position: memberAccessRef.declName.positionAfterSkippingLeadingTrivia,
                reason: """
                Avoid calling navigationTitle(_:) with string literals. \
                Use String.init if this string should be translated, otherwise use navigationTitle(verbatim:)
                """
            )
        }

        return nil
    }
}

private extension NavigationTitleRule.Visitor {
    func reason(position: AbsolutePosition, reason: String) -> ReasonedRuleViolation {
        .init(
            position: position,
            reason: reason,
            severity: .warning
        )
    }
}
