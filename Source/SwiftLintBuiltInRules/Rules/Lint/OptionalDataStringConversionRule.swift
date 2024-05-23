import SwiftSyntax

@SwiftSyntaxRule
struct OptionalDataStringConversionRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    static let description = RuleDescription(
        identifier: "optional_data_string_conversion",
        name: "Optional Data -> String Conversion",
        description: "Prefer using failable String(data:encoding:) when converting from `Data` to a UTF-8 `String`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("String(data: data, encoding: .utf8)")
        ],
        triggeringExamples: [
            Example("String(decoding: data, as: UTF8.self)")
        ]
    )
}

private extension OptionalDataStringConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: DeclReferenceExprSyntax) {
            if node.baseName.text == "String",
               let parent = node.parent?.as(FunctionCallExprSyntax.self),
               parent.arguments.map({ $0.label?.text }) == ["decoding", "as"],
               parent.arguments.last?.expression.as(IdentifierTypeSyntax.self)?.name == "UTF8.self" {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}
