import SwiftSyntax

@SwiftSyntaxRule
struct NonOptionalStringDataConversionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    static let description = RuleDescription(
        identifier: "non_optional_string_data_conversion",
        name: "Non-optional String <-> Data Conversion",
        description: "Prefer the non-optional initializers when converting between `String` and `Data` (e.g. `Data(_:)` and `String(decoding:as:)`)",
        kind: .lint,
        nonTriggeringExamples: [
            Example("Data(\"foo\".utf8)"),
            Example("String(decoding: data, as: UTF8.self)"),
        ],
        triggeringExamples: [
            Example("\"foo\".data(using: .utf8)"),
            Example("String(data: data, encoding: .utf8)"),
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
    }
}

private extension MemberAccessExprSyntax {
    var isUTF8: Bool {
        declName.baseName.text == "utf8"
    }
}
