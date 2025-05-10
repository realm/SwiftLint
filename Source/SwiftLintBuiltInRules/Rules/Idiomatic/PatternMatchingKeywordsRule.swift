import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PatternMatchingKeywordsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: "Combine multiple pattern matching bindings by moving keywords out of tuples",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("default"),
            Example("case 1"),
            Example("case bar"),
            Example("case let (x, y)"),
            Example("case .foo(let x)"),
            Example("case let .foo(x, y)"),
            Example("case .foo(let x), .bar(let x)"),
            Example("case .foo(let x, var y)"),
            Example("case var (x, y)"),
            Example("case .foo(var x)"),
            Example("case var .foo(x, y)"),
            Example("case (y, let x, z)"),
        ].map(wrapInSwitch),
        triggeringExamples: [
            Example("case (↓let x,  ↓let y)"),
            Example("case (↓let x,  ↓let y, .foo)"),
            Example("case (↓let x,  ↓let y, _)"),
            Example("case (↓let x,  ↓let y, f())"),
            Example("case (↓let x,  ↓let y, s.f())"),
            Example("case (↓let x,  ↓let y, s.t)"),
            Example("case .foo(↓let x, ↓let y)"),
            Example("case (.yamlParsing(↓let x), .yamlParsing(↓let y))"),
            Example("case (↓var x,  ↓var y)"),
            Example("case .foo(↓var x, ↓var y)"),
            Example("case (.yamlParsing(↓var x), .yamlParsing(↓var y))"),
        ].map(wrapInSwitch)
    )

    private static func wrapInSwitch(_ example: Example) -> Example {
        example.with(code: """
            switch foo {
                \(example.code): break
            }
            """)
    }
}

private extension PatternMatchingKeywordsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchCaseItemSyntax) {
            let localViolations = TupleVisitor(configuration: configuration, file: file)
                .walk(tree: node.pattern, handler: \.violations)
            violations.append(contentsOf: localViolations)
        }
    }
}

private final class TupleVisitor<Configuration: RuleConfiguration>: ViolationsSyntaxVisitor<Configuration> {
    override func visitPost(_ node: LabeledExprListSyntax) {
        let list = node.flatteningEnumPatterns().map(\.expression.categorized)
        if list.contains(where: \.isReference) {
            return
        }
        let specifiers = list.compactMap { if case let .binding(specifier) = $0 { specifier } else { nil } }
        if specifiers.count > 1, specifiers.allSatisfy({ $0.tokenKind == specifiers.first?.tokenKind }) {
            violations.append(contentsOf: specifiers.map(\.positionAfterSkippingLeadingTrivia))
        }
    }
}

private extension LabeledExprListSyntax {
    func flatteningEnumPatterns() -> [LabeledExprSyntax] {
        flatMap { elem in
            guard let pattern = elem.expression.as(FunctionCallExprSyntax.self),
                  pattern.calledExpression.is(MemberAccessExprSyntax.self) else {
                return [elem]
            }

            return Array(pattern.arguments)
        }
    }
}

private enum ArgumentType {
    case binding(specifier: TokenSyntax)
    case reference
    case constant

    var isReference: Bool {
        switch self {
        case .reference: true
        default: false
        }
    }
}

private extension ExprSyntax {
    var categorized: ArgumentType {
        if let binding = `as`(PatternExprSyntax.self)?.pattern.as(ValueBindingPatternSyntax.self) {
            return .binding(specifier: binding.bindingSpecifier)
        }
        if `is`(DeclReferenceExprSyntax.self) {
            return .reference
        }
        return .constant
    }
}
