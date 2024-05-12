import SwiftSyntax

@SwiftSyntaxRule
struct FunctionParametersNewlineRule: OptInRule {
    var configuration = FunctionParametersNewlineConfiguration()

    static let description = RuleDescription(
        identifier: "function_parameters_newline",
        name: "Function parameters newline",
        description: "Function parameters should be on a new line",
        kind: .lint,
        nonTriggeringExamples: [
            Example("func foo() {}", configuration: ["leading_paren_on_newline": true, "trailing_paren_on_newline": true]),
            Example("func foo() {}"),
            Example("""
            func foo(bar: Bar,
                baz: Baz) {}
            """),
            Example("""
            func foo(
                bar: Bar,
                baz: Baz) {}
            """),
            Example("""
            func foo(
                bar: Bar,
                baz: Baz
            ) {}
            """),
            Example("""
            func foo(
                bar: Bar,
                baz: Baz
            ) {}
            """, configuration: ["leading_paren_on_newline": true, "trailing_paren_on_newline": true]),
            Example("""
            func foo(bar: Bar,
                bar: Bar
            ) {}
            """),
            Example("init(bar: Bar) {}"),
        ],
        triggeringExamples: [
            Example("func foo(bar: Bar, ↓baz: Baz) {}"),
            Example("func foo(↓bar: Bar, ↓baz: Baz) {}", configuration: ["leading_paren_on_newline": true]),
            Example("func foo(bar: Bar, ↓baz: Baz↓) {}", configuration: ["trailing_paren_on_newline": true]),
            Example("init(bar: Bar, ↓baz: Baz, ↓foo: Foo) {}"),
            Example("""
            func foo(bar: Bar,
                bar: Bar, ↓foo: Foo
            ) {}
            """),
        ]
    )
}

private extension FunctionParametersNewlineRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionParameterClauseSyntax) {
            if configuration.leadingParenOnNewline, let parameter = node.parameters.first, parameter.isMissingLeadingNewline {
                violations.append(parameter.positionAfterSkippingLeadingTrivia)
            }

            guard node.parameters.count > 1 else {
                return
            }

            let parameters = node.parameters.dropFirst()

            for parameter in parameters where parameter.isMissingLeadingNewline {
                violations.append(parameter.positionAfterSkippingLeadingTrivia)
            }

            if configuration.trailingParenOnNewline, node.rightParen.isMissingLeadingNewline {
                violations.append(node.rightParen.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

fileprivate extension FunctionParameterSyntax {
    var isMissingLeadingNewline: Bool {
        return leadingTrivia.isEmpty || leadingTrivia.first?.isNewline == false
    }
}

fileprivate extension TokenSyntax {
    var isMissingLeadingNewline: Bool {
        return leadingTrivia.isEmpty || leadingTrivia.first?.isNewline == false
    }
}
