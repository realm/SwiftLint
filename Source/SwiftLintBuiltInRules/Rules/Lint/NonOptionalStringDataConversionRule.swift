import SwiftSyntax

@SwiftSyntaxRule
struct NonOptionalStringDataConversionRule: Rule {
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
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if node.base?.is(StringLiteralExprSyntax.self) == true,
               node.declName.baseName.text == "data",
               let parent = node.parent?.as(FunctionCallExprSyntax.self),
               let argument = parent.arguments.onlyElement,
               argument.label?.text == "using",
               argument.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: DeclReferenceExprSyntax) {
            if node.baseName.text == "String",
               let parent = node.parent?.as(FunctionCallExprSyntax.self),
               parent.arguments.map({ $0.label?.text }) == ["data", "encoding"],
               parent.arguments.last?.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true {
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
