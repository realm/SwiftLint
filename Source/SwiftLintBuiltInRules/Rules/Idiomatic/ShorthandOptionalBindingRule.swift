import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ShorthandOptionalBindingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "shorthand_optional_binding",
        name: "Shorthand Optional Binding",
        description: "Use shorthand syntax for optional binding",
        kind: .idiomatic,
        minSwiftVersion: .fiveDotSeven,
        nonTriggeringExamples: [
            Example("""
                if let i {}
                if let i = a {}
                guard let i = f() else {}
                if var i = i() {}
                if let i = i as? Foo {}
                guard let `self` = self else {}
                while var i { i = nil }
                """),
            Example("""
                if let i,
                   var i = a,
                   j > 0 {}
                """, excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("""
                if ↓let i = i {}
                if ↓let self = self {}
                if ↓var `self` = `self` {}
                if i > 0, ↓let j = j {}
                if ↓let i = i, ↓var j = j {}
                """),
            Example("""
                if ↓let i = i,
                   ↓var j = j,
                   j > 0 {}
                """, excludeFromDocumentation: true),
            Example("""
                guard ↓let i = i else {}
                guard ↓let self = self else {}
                guard ↓var `self` = `self` else {}
                guard i > 0, ↓let j = j else {}
                guard ↓let i = i, ↓var j = j else {}
                """),
            Example("""
                while ↓var i = i { i = nil }
                """),
        ],
        corrections: [
            Example("""
                if ↓let i = i {}
                """): Example("""
                    if let i {}
                    """),
            Example("""
                if ↓let self = self {}
                """): Example("""
                    if let self {}
                    """),
            Example("""
                if ↓var `self` = `self` {}
                """): Example("""
                    if var `self` {}
                    """),
            Example("""
                guard ↓let i = i, ↓var j = j  , ↓let k  =k else {}
                """): Example("""
                    guard let i, var j  , let k else {}
                    """),
            Example("""
                while j > 0, ↓var i = i   { i = nil }
                """): Example("""
                    while j > 0, var i   { i = nil }
                    """),
        ],
        deprecatedAliases: ["if_let_shadowing"]
    )
}

private extension ShorthandOptionalBindingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: OptionalBindingConditionSyntax) {
            if node.isShadowingOptionalBinding {
                violations.append(node.bindingSpecifier.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: OptionalBindingConditionSyntax) -> OptionalBindingConditionSyntax {
            guard node.isShadowingOptionalBinding else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let newNode = node
                .with(\.initializer, nil)
                .with(\.pattern, node.pattern.with(\.trailingTrivia, node.trailingTrivia))
            return super.visit(newNode)
        }
    }
}

private extension OptionalBindingConditionSyntax {
    var isShadowingOptionalBinding: Bool {
        if let id = pattern.as(IdentifierPatternSyntax.self),
           let value = initializer?.value.as(DeclReferenceExprSyntax.self),
           id.identifier.text == value.baseName.text {
            return true
        }
        return false
    }
}
