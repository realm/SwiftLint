import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct PatternMatchingKeywordsRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    enum Reason {
        static let tuples = """
            Combine multiple pattern bindings by moving binding keywords out of tuple
            """
        static let enumAssociatedValues = """
            Combine multiple pattern bindings by moving binding keywords out of associated values
            """
    }

    static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: """
            Combine multiple pattern matching bindings by moving binding keywords out of tuples and associated values
            in enum cases to reduce visual noise.
            """,
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
        ].map(wrapInSwitch) + [
            Example("if case let (x, y) = foo {}"),
            Example("guard case let (x, y) = foo else { return }"),
            Example("while case let (x, y) = foo {}"),
            Example("for case let (x, y) in foos {}"),
            Example("if case (foo, let x) = value {}"),
            Example("guard case .foo(bar, let x) = value else { return }"),
            Example("do {} catch let Pattern.error(x, y) {}"),
            Example("do {} catch (foo, let x) {}"),
        ],
        triggeringExamples: [
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
        ].map(wrapInSwitch) + [
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

    private static func wrapInSwitch(_ example: Example) -> Example {
        example.with(code: """
            switch foo {
                \(example.code): break
            }
            """
        )
    }
}

private extension PatternMatchingKeywordsRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchCaseItemSyntax) {
            collectViolations(from: node.pattern)
        }

        override func visitPost(_ node: MatchingPatternConditionSyntax) {
            collectViolations(from: node.pattern)
        }

        override func visitPost(_ node: ForStmtSyntax) {
            guard node.caseKeyword != nil else {
                return
            }

            collectViolations(from: node.pattern)
        }

        override func visitPost(_ node: CatchItemSyntax) {
            guard let pattern = node.pattern else {
                return
            }

            collectViolations(from: pattern)
        }

        private func collectViolations(from pattern: PatternSyntax) {
            if let binding = pattern.as(ValueBindingPatternSyntax.self) {
                collectViolations(from: binding.pattern)
                return
            }

            guard let expression = pattern.as(ExpressionPatternSyntax.self)?.expression else {
                return
            }

            collectViolations(from: expression)
        }

        private func collectViolations(from expression: ExprSyntax) {
            guard let childExpressions = expression.immediatePatternGroupChildren else {
                if let pattern = expression.as(PatternExprSyntax.self)?.pattern {
                    collectViolations(from: pattern)
                }

                return
            }

            let categories = childExpressions.map(GroupCategory.from(expression:))

            if !categories.contains(.reference) {
                let specifiers = categories.compactMap {
                    if case let .binding(specifier) = $0 { return specifier }
                    return nil
                }

                if specifiers.count > 1,
                   let first = specifiers.first,
                   specifiers.allSatisfy({ $0.tokenKind == first.tokenKind }) {
                    let reason = expression.is(TupleExprSyntax.self)
                        ? Reason.tuples
                        : Reason.enumAssociatedValues

                    violations.append(contentsOf: specifiers.map {
                        ReasonedRuleViolation(position: $0.positionAfterSkippingLeadingTrivia, reason: reason)
                    })
                }
            }

            for childExpression in childExpressions {
                collectViolations(from: childExpression)
            }
        }
    }
}

private enum GroupCategory: Equatable {
    case binding(specifier: TokenSyntax)
    case reference
    case neutral

    static func from(expression: ExprSyntax) -> Self {
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
            return liftedCategory(from: childExpressions)
        }

        return .neutral
    }

    private static func liftedCategory(from expressions: [ExprSyntax]) -> Self {
        let categories = expressions.map { from(expression: $0) }

        if categories.contains(.reference) {
            return .neutral
        }

        let specifiers = categories.compactMap {
            if case let .binding(specifier) = $0 { return specifier }
            return nil
        }
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
