import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PatternMatchingKeywordsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: """
            Combine multiple pattern matching bindings by moving keywords out of tuples
            and enum associated values
            """,
        kind: .idiomatic,
        nonTriggeringExamples: switchWrapped(examples: [
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
            Example("case (foo, let x)"),
            Example("case (foo, let x, let y)"),
            Example("case .foo(bar, let x)"),
            Example("case (let x, y)"),
            Example("case .foo(let x, y)"),
            Example("case (.foo(let x), y)"),
            Example("case let .foo(x, y), let .bar(x, y)"),
            Example("case var .foo(x, y), var .bar(x, y)"),
            Example("case let .foo(x, y), let .bar(x, y), let .baz(x, y)"),
            Example("case .foo(bar: let x, baz: var y)"),
            Example("case (.yamlParsing(var x), (.yamlParsing(var y), z))"),
            Example("case (.foo(let x), (y, let z))"),
        ]) + [
            Example("if case let (x, y) = foo {}"),
            Example("guard case let (x, y) = foo else { return }"),
            Example("while case let (x, y) = foo {}"),
            Example("for case let (x, y) in foos {}"),
            Example("if case (foo, let x) = value {}"),
            Example("guard case .foo(bar, let x) = value else { return }"),
            Example("do {} catch let Pattern.error(x, y) {}"),
            Example("do {} catch (foo, let x) {}"),
        ],
        triggeringExamples: switchWrapped(examples: [
            Example("case (↓let x, ↓let y)"),
            Example("case (↓let x, ↓let y, .foo)"),
            Example("case (↓let x, ↓let y, _)"),
            Example("case (↓let x, ↓let y, 1)"),
            Example("case (↓let x, ↓let y, f())"),
            Example("case (↓let x, ↓let y, s.f())"),
            Example("case (↓let x, ↓let y, s.t)"),
            Example("case .foo(↓let x, ↓let y)"),
            Example("case .foo(bar: ↓let x, baz: ↓let y)"),
            Example("case .foo(↓var x, ↓var y)"),
            Example("case .foo(bar: ↓var x, baz: ↓var y)"),
            Example("case (.yamlParsing(↓let x), .yamlParsing(↓let y))"),
            Example("case (.yamlParsing(↓var x), (.yamlParsing(↓var y), _))"),
            Example("case ((↓let x, ↓let y), z)"),
            Example("case .foo((↓let x, ↓let y), z)"),
            Example("case (.foo(↓let x, ↓let y), z)"),
            Example("case .foo(.bar(↓let x), .bar(↓let y))"),
            Example("case .foo(.bar(↓let x), .bar(↓let y), .baz)"),
            Example("case .foo(↓let x, ↓let y), .bar(↓let x, ↓let y)"),
            Example("case .foo(↓var x, ↓var y), .bar(↓var x, ↓var y)"),
        ]) + [
            Example("if case (↓let x, ↓let y) = foo {}"),
            Example("guard case (↓let x, ↓let y) = foo else { return }"),
            Example("while case (↓let x, ↓let y) = foo {}"),
            Example("for case (↓let x, ↓let y) in foos {}"),
            Example("if case .foo(bar: ↓let x, baz: ↓let y) = value {}"),
            Example("do {} catch Pattern.error(↓let x, ↓let y) {}"),
            Example("do {} catch (↓let x, ↓let y) {}"),
            Example("do {} catch Foo.outer(.inner(↓let x), .inner(↓let y)) {}"),
        ]
    )

    private static func switchWrapped(examples: [Example]) -> [Example] {
        examples.map { example in
            example.with(
                code: """
                switch foo {
                    \(example.code): break
                }
                """
            )
        }
    }
}

private extension PatternMatchingKeywordsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchCaseItemSyntax) {
            appendViolations(from: node.pattern)
        }

        override func visitPost(_ node: MatchingPatternConditionSyntax) {
            appendViolations(from: node.pattern)
        }

        override func visitPost(_ node: ForStmtSyntax) {
            guard node.caseKeyword != nil else {
                return
            }

            appendViolations(from: node.pattern)
        }

        override func visitPost(_ node: CatchItemSyntax) {
            guard let pattern = node.pattern else {
                return
            }

            appendViolations(from: pattern)
        }

        private func appendViolations(from pattern: PatternSyntax) {
            violations.append(contentsOf: PatternViolationCollector.collect(in: pattern))
        }
    }
}

private enum PatternViolationCollector {
    static func collect(in pattern: PatternSyntax) -> [AbsolutePosition] {
        var violations: [AbsolutePosition] = []
        collect(from: pattern, into: &violations)
        return violations
    }

    private static func collect(from pattern: PatternSyntax, into violations: inout [AbsolutePosition]) {
        if let binding = pattern.as(ValueBindingPatternSyntax.self) {
            collect(from: binding.pattern, into: &violations)
            return
        }

        guard let expression = pattern.as(ExpressionPatternSyntax.self)?.expression else {
            return
        }

        collect(from: expression, into: &violations)
    }

    private static func collect(from expression: ExprSyntax, into violations: inout [AbsolutePosition]) {
        if let childExpressions = expression.immediatePatternGroupChildren {
            appendViolationsIfBindingsCanBeLifted(from: childExpressions, into: &violations)

            for childExpression in childExpressions {
                collect(from: childExpression, into: &violations)
            }

            return
        }

        if let pattern = expression.as(PatternExprSyntax.self)?.pattern {
            collect(from: pattern, into: &violations)
        }
    }

    private static func appendViolationsIfBindingsCanBeLifted(
        from expressions: [ExprSyntax],
        into violations: inout [AbsolutePosition]
    ) {
        let categories = expressions.map(GroupCategoryResolver.category(for:))

        if categories.contains(where: \.isReference) {
            return
        }

        let specifiers = categories.compactMap(\.bindingSpecifier)
        guard specifiers.count > 1, let first = specifiers.first else {
            return
        }

        if specifiers.allSatisfy({ $0.tokenKind == first.tokenKind }) {
            violations.append(contentsOf: specifiers.map(\.positionAfterSkippingLeadingTrivia))
        }
    }
}

private enum GroupCategory {
    case binding(specifier: TokenSyntax)
    case reference
    case neutral

    var isReference: Bool {
        switch self {
        case .reference:
            return true
        default:
            return false
        }
    }

    var bindingSpecifier: TokenSyntax? {
        switch self {
        case let .binding(specifier):
            return specifier
        default:
            return nil
        }
    }
}

private enum GroupCategoryResolver {
    static func category(for expression: ExprSyntax) -> GroupCategory {
        if let binding = expression.as(PatternExprSyntax.self)?.pattern.as(ValueBindingPatternSyntax.self) {
            return .binding(specifier: binding.bindingSpecifier)
        }

        // `case (foo, let x)` must not become `case let (foo, x)`,
        // because `foo` would stop matching an existing value and
        // would instead become a newly introduced binding.
        if expression.is(DeclReferenceExprSyntax.self) {
            return .reference
        }

        if let childExpressions = expression.immediatePatternGroupChildren {
            return liftedCategory(for: childExpressions)
        }

        return .neutral
    }

    private static func liftedCategory(for expressions: [ExprSyntax]) -> GroupCategory {
        let categories = expressions.map(category(for:))

        if categories.contains(where: \.isReference) {
            return .neutral
        }

        let specifiers = categories.compactMap(\.bindingSpecifier)
        guard let first = specifiers.first else {
            return .neutral
        }

        if specifiers.allSatisfy({ $0.tokenKind == first.tokenKind }) {
            return .binding(specifier: first)
        }

        return .neutral
    }
}

private extension ExprSyntax {
    var immediatePatternGroupChildren: [ExprSyntax]? {
        if let tuple = `as`(TupleExprSyntax.self) {
            return tuple.elements.map(\.expression)
        }

        if let call = `as`(FunctionCallExprSyntax.self),
           call.calledExpression.is(MemberAccessExprSyntax.self) {
            return call.arguments.map(\.expression)
        }

        return nil
    }
}
