import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule
struct NonOptionalStringDataConversionRule: Rule {
    var configuration = NonOptionalStringDataConversionConfiguration()

    private static let variablesIncluded = ["include_variables": true]

    static let description = RuleDescription(
        identifier: "non_optional_string_data_conversion",
        name: "Non-optional String -> Data Conversion",
        description: "Prefer non-optional `Data(_:)` initializer when converting `String` to `Data`",
        kind: .lint,
        nonTriggeringExamples: [
            Example("Data(\"foo\".utf8)"),
            Example("Data(string.utf8)"),
            Example("\"foo\".data(using: .ascii)"),
            Example("string.data(using: .unicode)"),
            Example("Data(\"foo\".utf8)", configuration: variablesIncluded),
            Example("Data(string.utf8)", configuration: variablesIncluded),
            Example("\"foo\".data(using: .ascii)", configuration: variablesIncluded),
            Example("string.data(using: .unicode)", configuration: variablesIncluded),
        ],
        triggeringExamples: [
            Example("↓\"foo\".data(using: .utf8)"),
            Example("↓\"foo\".data(using: .utf8)", configuration: variablesIncluded),
            Example("↓string.data(using: .utf8)", configuration: variablesIncluded),
            Example("↓property.data(using: .utf8)", configuration: variablesIncluded),
            Example("↓obj.property.data(using: .utf8)", configuration: variablesIncluded),
            Example("↓getString().data(using: .utf8)", configuration: variablesIncluded),
            Example("↓getValue()?.data(using: .utf8)", configuration: variablesIncluded),
        ]
    )
}

private extension NonOptionalStringDataConversionRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: MemberAccessExprSyntax) {
            if node.declName.baseName.text == "data",
               let parent = node.parent?.as(FunctionCallExprSyntax.self),
               let argument = parent.arguments.onlyElement,
               argument.label?.text == "using",
               argument.expression.as(MemberAccessExprSyntax.self)?.isUTF8 == true,
               let base = node.base,
               base.is(StringLiteralExprSyntax.self) || configuration.includeVariables {
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
