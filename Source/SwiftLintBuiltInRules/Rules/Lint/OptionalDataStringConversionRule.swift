import SwiftSyntax

@SwiftSyntaxRule
struct OptionalDataStringConversionRule: Rule {
    var configuration = OptionalDataStringConversionConfiguration()

    static let description = RuleDescription(
        identifier: "optional_data_string_conversion",
        name: "Optional Data -> String Conversion",
        description: "Prefer failable `String(bytes:encoding:)` initializer when converting `Data` to `String`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("String(data: data, encoding: .utf8)"),
            Example("String(bytes: data, encoding: .utf8)"),
            Example("String(UTF8.self)"),
            Example("String(a, b, c, UTF8.self)"),
            Example("String(decoding: data, encoding: UTF8.self)"),
            Example("let text: String = .init(decoding: data, as: UTF8.self)"),
        ],
        triggeringExamples: [
            Example("↓String(decoding: data, as: UTF8.self)"),
            Example("↓String.init(decoding: data, as: UTF8.self)"),
        ]
    )
}

private extension OptionalDataStringConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard hasDecodingAsUTF8Arguments(node) else {
                return
            }

            let calledExpression = node.calledExpression

            // Case 1: String(decoding:as:)
            if let declRef = calledExpression.as(DeclReferenceExprSyntax.self),
               declRef.baseName.text == "String" {
                violations.append(declRef.positionAfterSkippingLeadingTrivia)
                return
            }

            guard let memberAccess = calledExpression.as(MemberAccessExprSyntax.self),
                  memberAccess.declName.baseName.text == "init" else {
                return
            }

            // Case 2: String.init(decoding:as:)
            if let base = memberAccess.base,
               let declRef = base.as(DeclReferenceExprSyntax.self),
               declRef.baseName.text == "String" {
                violations.append(declRef.positionAfterSkippingLeadingTrivia)
                return
            }

            // Case 3: .init(decoding:as:) — only with include_bare_init
            if memberAccess.base == nil, configuration.includeBareInit {
                let reason = "Prefer failable `String(bytes:encoding:)` — assuming `.init` refers to `String.init`"
                violations.append(
                    ReasonedRuleViolation(
                        position: memberAccess.period.positionAfterSkippingLeadingTrivia,
                        reason: reason
                    )
                )
            }
        }

        private func hasDecodingAsUTF8Arguments(_ node: FunctionCallExprSyntax) -> Bool {
            guard node.arguments.map(\.label?.text) == ["decoding", "as"],
                  let expr = node.arguments.last?.expression.as(MemberAccessExprSyntax.self),
                  expr.base?.description == "UTF8",
                  expr.declName.baseName.description == "self" else {
                return false
            }
            return true
        }
    }
}
