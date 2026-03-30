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
        ],
        triggeringExamples: [
            Example("String(decoding: data, as: UTF8.self)"),
            Example("String.init(decoding: data, as: UTF8.self)"),
            Example("let text: String = .init(decoding: data, as: UTF8.self)"),
        ],
    )
}

private extension OptionalDataStringConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if node.arguments.map(\.label?.text) == ["decoding", "as"],
               let expr = node.arguments.last?.expression.as(MemberAccessExprSyntax.self),
               expr.base?.description == "UTF8",
               expr.declName.baseName.description == "self",
               node.calledExpression.isOptionalDataStringInitializer {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension ExprSyntax {
    var isOptionalDataStringInitializer: Bool {
        if let declReference = `as`(DeclReferenceExprSyntax.self) {
            return declReference.baseName.text == "String"
        }

        guard let memberAccess = `as`(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "init" else {
            return false
        }

        if memberAccess.base == nil {
            return true
        }

        return memberAccess.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "String"
    }
}
