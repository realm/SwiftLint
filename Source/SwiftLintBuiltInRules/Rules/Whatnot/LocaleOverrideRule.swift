import SwiftLintCore
import SwiftSyntax

struct LocaleOverrideRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "locale_override",
        name: "Locale Override",
        description: "Please use Locale.overriddenOrCurrent",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let df = Locale.overriddenOrCurrent"),
            Example("Locale.overriddenOrCurrent"),
            Example("locale: .overriddenOrCurrent")
        ],
        triggeringExamples: [
            Example("let locale = ↓Locale.init()"),
            Example("let locale = ↓Locale()"),
            Example("""
                let locale = ↓Locale(identifier: "en_US")
            """),
            Example("let locale = ↓Locale.current"),
            Example("↓Locale()"),
            Example("↓Locale.init()"),
            Example("↓Locale.current"),
            Example("""
                Decimal(string: "123", ↓locale: .current)
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
        Visitor(configuration: configuration, file: file)
    }
}

private extension LocaleOverrideRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if isReferencingCurrentLocale(node) {
                violations.append(reason(position: node.positionAfterSkippingLeadingTrivia))
            } else if isReferencingLocaleInit(node) {
                violations.append(reason(position: node.positionAfterSkippingLeadingTrivia))
            }
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if isLocaleInitializer(node) {
                violations.append(reason(position: node.positionAfterSkippingLeadingTrivia))
            } else if let localeArgument = currentLocaleAsFunctionArgument(node) {
                violations.append(reason(position: localeArgument.positionAfterSkippingLeadingTrivia))
            }
        }
    }
}

private extension LocaleOverrideRule.Visitor {
    func isReferencingCurrentLocale(_ node: MemberAccessExprSyntax) -> Bool {
        if let identifierExp = node.base?.as(DeclReferenceExprSyntax.self),
           identifierExp.baseName.text == "Locale",
           node.declName.baseName.text == "current" {
            return true
        }

        return false
    }

    func isReferencingLocaleInit(_ node: MemberAccessExprSyntax) -> Bool {
        node.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "Locale"
            && node.declName.baseName.text == "init"
    }

    func isLocaleInitializer(_ node: FunctionCallExprSyntax) -> Bool {
        if node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "Locale" {
            return true
        }

        return false
    }

    func currentLocaleAsFunctionArgument(_ node: FunctionCallExprSyntax) -> LabeledExprListSyntax.Element? {
        node.arguments.first(where: { element in
            element.label?.text == "locale"
                && element.expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "current"
        })
    }
}

private extension LocaleOverrideRule.Visitor {
    func reason(position: AbsolutePosition) -> ReasonedRuleViolation {
        .init(
            position: position,
            reason: """
            Locale.overriddenOrCurrent allows us to override the locale \
            for testing purposes; prefer it over other instances of Locale
            """,
            severity: .warning
        )
    }
}
