import SwiftSyntax

@SwiftSyntaxRule
struct OptionalDataStringConversionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

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
            Example("let text: String = .init(data: data, encoding: .utf8)"),
        ],
        triggeringExamples: [
            Example("String(decoding: data, as: UTF8.self)"),
            Example("let text: String = .init(decoding: data, as: UTF8.self)"),
        ]
    )
}

private extension OptionalDataStringConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard node.arguments.map(\.label?.text) == ["decoding", "as"],
                  let lastExpr = node.arguments.last?.expression.as(MemberAccessExprSyntax.self),
                  lastExpr.base?.description == "UTF8",
                  lastExpr.declName.baseName.description == "self" else {
                return
            }

            if let declRef = node.calledExpression.as(DeclReferenceExprSyntax.self),
               declRef.baseName.text == "String" {
                // String(decoding: data, as: UTF8.self)
                violations.append(declRef.positionAfterSkippingLeadingTrivia)
            } else if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
                      memberAccess.base == nil,
                      memberAccess.declName.baseName.text == "init" {
                // .init(decoding: data, as: UTF8.self)
                violations.append(memberAccess.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
