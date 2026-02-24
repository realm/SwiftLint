import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct OptionalDataStringConversionRule: Rule {
    var configuration = OptionalDataStringConversionConfiguration()

    private static let shorthandInitIncluded = ["include_shorthand_init": true]

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
            Example("let text: String = ↓.init(decoding: data, as: UTF8.self)", configuration: shorthandInitIncluded),
        ]
    )
}

private extension OptionalDataStringConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            let isShorthandInitCall = configuration.includeShorthandInit && node.isShorthandInitDecodingCall
            guard node.isStringDecodingCall || isShorthandInitCall else {
                return
            }

            if let expr = node.arguments.last?.expression.as(MemberAccessExprSyntax.self),
               expr.base?.trimmedDescription == "UTF8",
               expr.declName.baseName.text == "self",
               node.arguments.map(\.label?.text) == ["decoding", "as"] {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension FunctionCallExprSyntax {
    var isStringDecodingCall: Bool {
        if let declReferenceExpr = calledExpression.as(DeclReferenceExprSyntax.self) {
            return declReferenceExpr.baseName.text == "String"
        }

        if let memberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccessExpr.declName.baseName.text == "init" &&
                memberAccessExpr.base?.as(DeclReferenceExprSyntax.self)?.baseName.text == "String"
        }

        return false
    }

    var isShorthandInitDecodingCall: Bool {
        if let memberAccessExpr = calledExpression.as(MemberAccessExprSyntax.self) {
            return memberAccessExpr.declName.baseName.text == "init" && memberAccessExpr.base == nil
        }

        return false
    }
}
