import SwiftSyntax

struct PatternMatchingKeywordsRule: SwiftSyntaxRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "pattern_matching_keywords",
        name: "Pattern Matching Keywords",
        description: "Combine multiple pattern matching bindings by moving keywords out of tuples",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "default",
            "case 1",
            "case bar",
            "case let (x, y)",
            "case .foo(let x)",
            "case let .foo(x, y)",
            "case .foo(let x), .bar(let x)",
            "case .foo(let x, var y)",
            "case var (x, y)",
            "case .foo(var x)",
            "case var .foo(x, y)"
        ].map(wrapInSwitch),
        triggeringExamples: [
            "case (↓let x,  ↓let y)",
            "case (↓let x,  ↓let y, .foo)",
            "case (↓let x,  ↓let y, _)",
            "case .foo(↓let x, ↓let y)",
            "case (.yamlParsing(↓let x), .yamlParsing(↓let y))",
            "case (↓var x,  ↓var y)",
            "case .foo(↓var x, ↓var y)",
            "case (.yamlParsing(↓var x), .yamlParsing(↓var y))"
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
                let firstLetOrVar = list.first?.bindingKeyword.tokenKind else {
                return
            }

            let hasViolation = list.allSatisfy { elem in
                elem.bindingKeyword.tokenKind == firstLetOrVar
            }

            guard hasViolation else {
                return
            }

            violations.append(contentsOf: list.compactMap { elem in
                return elem.bindingKeyword.positionAfterSkippingLeadingTrivia
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
