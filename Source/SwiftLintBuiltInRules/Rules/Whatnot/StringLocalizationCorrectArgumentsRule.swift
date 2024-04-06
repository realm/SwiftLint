import SwiftLintCore
import SwiftSyntax

struct StringLocalizationCorrectArgumentsRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "string_localization",
        name: "String Localization",
        description: "Please use String.init(localized:defaultValue:bundle:comment:)",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                String(localized: "a", defaultValue: "b", bundle: .module, comment: "d")
            """),
            Example("""
                AttributedString(localized: "a", defaultValue: "b", bundle: .module, comment: "d")
            """),
            Example("""
                String(
                    localized: "a",
                    defaultValue: "b",
                    bundle: .module,
                    comment: "d"
                )
            """),
            Example("""
                .init(
                    localized: "a",
                    defaultValue: "b",
                    bundle: .module,
                    comment: "d"
                )
            """)
        ],
        triggeringExamples: [
            Example("""
                ↓String(localized: "a", defaultValue: "b", comment: "d")
            """),
            Example("""
                ↓AttributedString(localized: "a", defaultValue: "b", comment: "d")
            """),
            Example("""
                ↓String(localized: "a", defaultValue: "b", bundle: .module)
            """),
            Example("""
                String(
                    localized: "a",
                    defaultValue: "b",
                    bundle: .module,
                    ↓comment: ""
                )
            """),
            Example("""
                AttributedString(
                    localized: "a",
                    defaultValue: "b",
                    bundle: .module,
                    ↓comment: ""
                )
            """),
            Example("""
                .init(
                    localized: "a",
                    defaultValue: "b",
                    bundle: .module,
                    ↓comment: ""
                )
            """),
            Example("""
                ↓.init(
                    localized: "a",
                    defaultValue: "b",
                    comment: "d"
                )
            """),
            Example("""
                String(
                    localized: "a",
                    ↓defaultValue: myString,
                    bundle: .module,
                    comment: "wow"
                )
            """),
            Example("""
                String(
                    localized: "a",
                    ↓defaultValue: isTrue ? "a": "b",
                    bundle: .module,
                    comment: "wow"
                )
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

private extension StringLocalizationCorrectArgumentsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let reason = isInvalidStringLocalizationInitializer(node) {
                violations.append(reason)
            } else if let reason = isInvalidTypeInferredStringLocalizationInitializer(node) {
                violations.append(reason)
            }
        }
    }
}

private extension StringLocalizationCorrectArgumentsRule.Visitor {
    func isInvalidStringLocalizationInitializer(_ node: FunctionCallExprSyntax) -> ReasonedRuleViolation? {
        guard let declRef = node.calledExpression.as(DeclReferenceExprSyntax.self) else { return nil }
        let isStringInit = declRef.baseName.text == "String"
        let isAttributedStringInit = declRef.baseName.text == "AttributedString"
        let hasLocalizedFirstArgument = node.arguments.first?.label?.text == "localized"

        if isStringInit || isAttributedStringInit, hasLocalizedFirstArgument {
            return hasInvalidArgumentsForStringLocalization(node)
        }

        return nil
    }

    func isInvalidTypeInferredStringLocalizationInitializer(_ node: FunctionCallExprSyntax) -> ReasonedRuleViolation? {
        guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return nil
        }

        let isTypeInferredInit = calledExpression.base == nil && calledExpression.declName.baseName.text == "init"
        let hasLocalizedFirstArgument = node.arguments.first?.label?.text == "localized"

        if isTypeInferredInit, hasLocalizedFirstArgument {
            return hasInvalidArgumentsForStringLocalization(node)
        }

        return nil
    }

    func hasInvalidArgumentsForStringLocalization(_ node: FunctionCallExprSyntax) -> ReasonedRuleViolation? {
        let defaultValueArgument = node.arguments.first { $0.label?.text == "defaultValue" }
        let bundleArgument = node.arguments.first { $0.label?.text == "bundle" }
        let commentArgument = node.arguments.first { $0.label?.text == "comment" }

        let hasAllFourArguments = defaultValueArgument != nil && bundleArgument != nil && commentArgument != nil
        let hasEmptyComment = commentArgument?.expression.as(StringLiteralExprSyntax.self)?.isEmptyString == true
        let hasLiteralDefaultValueArgument = defaultValueArgument?.expression.as(StringLiteralExprSyntax.self) != nil

        if !hasAllFourArguments {
            return reason(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: """
                Using String.init(localized:defaultValue:bundle:comment:) with all four arguments \
                will provide translators with context for the translation
                """
            )
        }

        if hasEmptyComment, let commentArgument {
            return reason(
                position: commentArgument.positionAfterSkippingLeadingTrivia,
                reason: """
                Comments are required to provide translators with enough context to properly translate the string
                """
            )
        }

        if !hasLiteralDefaultValueArgument, let defaultValueArgument {
            return reason(
                position: defaultValueArgument.positionAfterSkippingLeadingTrivia,
                reason: """
                Do not perform logic in or pass variables to the defaultValue argument. Only pass string literals
                """
            )
        }

        return nil
    }
}

private extension StringLocalizationCorrectArgumentsRule.Visitor {
    func reason(position: AbsolutePosition, reason: String) -> ReasonedRuleViolation {
        .init(
            position: position,
            reason: reason,
            severity: .warning
        )
    }
}
