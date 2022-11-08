import SwiftSyntax

struct PatternMatchingKeywordsRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: "Combine multiple pattern matching bindings by moving keywords out of tuples.",
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
            Example("case var .foo(x, y)")
        ].map(wrapInSwitch),
        triggeringExamples: [
            Example("case (↓let x,  ↓let y)"),
            Example("case (↓let x,  ↓let y, .foo)"),
            Example("case (↓let x,  ↓let y, _)"),
            Example("case .foo(↓let x, ↓let y)"),
            Example("case (.yamlParsing(↓let x), .yamlParsing(↓let y))"),
            Example("case (↓var x,  ↓var y)"),
            Example("case .foo(↓var x, ↓var y)"),
            Example("case (.yamlParsing(↓var x), .yamlParsing(↓var y))")
        ].map(wrapInSwitch)
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension PatternMatchingKeywordsRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: CaseItemSyntax) {
            let localViolations = TupleVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.pattern, handler: \.violations)
            violations.append(contentsOf: localViolations)
        }
    }

    final class TupleVisitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TupleExprElementListSyntax) {
            let list = node.flatteningEnumPatterns()
                .compactMap { elem in
                    elem.expression.asValueBindingPattern()
                }

            guard list.count > 1,
                let firstLetOrVar = list.first?.letOrVarKeyword.tokenKind else {
                return
            }

            let hasViolation = list.allSatisfy { elem in
                elem.letOrVarKeyword.tokenKind == firstLetOrVar
            }

            guard hasViolation else {
                return
            }

            violations.append(contentsOf: list.compactMap { elem in
                return elem.letOrVarKeyword.positionAfterSkippingLeadingTrivia
            })
        }
    }
}

private extension TupleExprElementListSyntax {
    func flatteningEnumPatterns() -> [TupleExprElementSyntax] {
        flatMap { elem in
            guard let pattern = elem.expression.as(FunctionCallExprSyntax.self),
                  pattern.calledExpression.is(MemberAccessExprSyntax.self) else {
                return [elem]
            }

            return Array(pattern.argumentList)
        }
    }
}

private extension ExprSyntax {
    func asValueBindingPattern() -> ValueBindingPatternSyntax? {
        if let pattern = self.as(UnresolvedPatternExprSyntax.self) {
            return pattern.pattern.as(ValueBindingPatternSyntax.self)
        }

        return nil
    }
}

private func wrapInSwitch(_ example: Example) -> Example {
    return example.with(code: """
        switch foo {
            \(example.code): break
        }
        """)
}
