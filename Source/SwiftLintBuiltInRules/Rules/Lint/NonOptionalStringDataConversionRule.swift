import SwiftSyntax

@SwiftSyntaxRule
struct NonOptionalStringDataConversionRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)
    static let description = RuleDescription(
        identifier: "non_optional_string_data_conversion",
        name: "Non-Optional String <-> Data Conversion",
        description: "Prefer using UTF8 encoded strings when converting between `String` and `Data`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("Data(\"foo\".utf8)"),
            Example("String(decoding: data, as: UTF8.self)")
        ],
        triggeringExamples: [
            Example("\"foo\".data(using: .utf8)"),
            Example("String(data: data, encoding: .utf8)")
        ]
    )
}

private extension NonOptionalStringDataConversionRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            print(node)
            if let expression = node.calledExpression.as(MemberAccessExprSyntax.self),
                  expression.base?.is(StringLiteralExprSyntax.self) == true,
                  expression.declName.baseName.text == "data",
                  let argument = node.arguments.onlyElement,
                  argument.label?.text == "using",
                  argument.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
            if let expression = node.calledExpression.as(DeclReferenceExprSyntax.self),
                  expression.baseName.text == "String",
                  node.arguments.map({ $0.label?.text }) == ["data", "encoding"],
                  node.arguments.last?.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension MemberAccessExprSyntax {
    var isUTF8: Bool {
        self.declName.baseName.text == "utf8"
    }
}
