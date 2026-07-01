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
        nonTriggeringExamples: #examples([
            "Data(\"foo\".utf8)",
            "Data(string.utf8)",
            "\"foo\".data(using: .ascii)",
            "string.data(using: .unicode)",
            "Data(\"foo\".utf8)".configuration(variablesIncluded),
            "Data(string.utf8)".configuration(variablesIncluded),
            "\"foo\".data(using: .ascii)".configuration(variablesIncluded),
            "string.data(using: .unicode)".configuration(variablesIncluded),
        ]),
        triggeringExamples: #examples([
            "↓\"foo\".data(using: .utf8)",
            "↓\"foo\".data(using: .utf8)".configuration(variablesIncluded),
            "↓string.data(using: .utf8)".configuration(variablesIncluded),
            "↓property.data(using: .utf8)".configuration(variablesIncluded),
            "↓obj.property.data(using: .utf8)".configuration(variablesIncluded),
            "↓getString().data(using: .utf8)".configuration(variablesIncluded),
            "↓getValue()?.data(using: .utf8)".configuration(variablesIncluded),
        ])
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
