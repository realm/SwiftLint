import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct OptionalEnumCaseMatchingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "optional_enum_case_matching",
        name: "Optional Enum Case Match",
        description: "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above",
        kind: .style,
        minSwiftVersion: .fiveDotOne,
        nonTriggeringExamples: [
            Example("""
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case (.bar, .baz): break
             case (.bar, _): break
             case (_, .baz): break
             default: break
            }
            """),
            Example("""
            switch (x, y) {
            case (.c, _?):
                break
            case (.c, nil):
                break
            case (_, _):
                break
            }
            """),
            // https://github.com/apple/swift/issues/61817
            Example("""
            switch bool {
            case true?:
              break
            case false?:
              break
            case .none:
              break
            }
            """, excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("""
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case (.bar↓?, .baz↓?): break
             case (.bar↓?, _): break
             case (_, .bar↓?): break
             default: break
            }
            """),
        ],
        corrections: [
            Example("""
            switch foo {
             case .bar↓?: break
             case .baz: break
             default: break
            }
            """): Example("""
            switch foo {
             case .bar: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case Foo.bar↓?: break
             case .baz: break
             default: break
            }
            """): Example("""
            switch foo {
             case Foo.bar: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓?, .baz↓?: break
             default: break
            }
            """): Example("""
            switch foo {
             case .bar, .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case .bar↓? where x > 1: break
             case .baz: break
             default: break
            }
            """): Example("""
            switch foo {
             case .bar where x > 1: break
             case .baz: break
             default: break
            }
            """),
            Example("""
            switch foo {
             case (.bar↓?, .baz↓?): break
             case (.bar↓?, _): break
             case (_, .bar↓?): break
             default: break
            }
            """): Example("""
            switch foo {
             case (.bar, .baz): break
             case (.bar, _): break
             case (_, .bar): break
             default: break
            }
            """),
        ]
    )
}

private extension OptionalEnumCaseMatchingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SwitchCaseItemSyntax) {
            guard let pattern = node.pattern.as(ExpressionPatternSyntax.self) else {
                return
            }

            if let expression = pattern.expression.as(OptionalChainingExprSyntax.self),
               !expression.expression.isDiscardAssignmentOrBoolLiteral {
                violations.append(expression.questionMark.positionAfterSkippingLeadingTrivia)
            } else if let expression = pattern.expression.as(TupleExprSyntax.self) {
                let optionalChainingExpressions = expression.optionalChainingExpressions()
                for optionalChainingExpression in optionalChainingExpressions {
                    violations.append(optionalChainingExpression.questionMark.positionAfterSkippingLeadingTrivia)
                }
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
            guard
                let pattern = node.pattern.as(ExpressionPatternSyntax.self),
                pattern.expression.is(OptionalChainingExprSyntax.self) || pattern.expression.is(TupleExprSyntax.self)
            else {
                return super.visit(node)
            }

            if let expression = pattern.expression.as(OptionalChainingExprSyntax.self),
               !expression.expression.isDiscardAssignmentOrBoolLiteral {
                let violationPosition = expression.questionMark.positionAfterSkippingLeadingTrivia
                correctionPositions.append(violationPosition)
                let newPattern = PatternSyntax(pattern.with(\.expression, expression.expression))
                let newNode = node
                    .with(\.pattern, newPattern)
                    .with(\.whereClause,
                          node.whereClause?.with(\.leadingTrivia, expression.questionMark.trailingTrivia))
                return super.visit(newNode)
            }
            if let expression = pattern.expression.as(TupleExprSyntax.self) {
                var newExpression = expression
                for element in expression.elements {
                    guard
                        let optionalChainingExpression = element.expression.as(OptionalChainingExprSyntax.self),
                        !optionalChainingExpression.expression.is(DiscardAssignmentExprSyntax.self)
                    else {
                        continue
                    }

                    let violationPosition = optionalChainingExpression.questionMark.positionAfterSkippingLeadingTrivia
                    correctionPositions.append(violationPosition)

                    let newElement = element.with(\.expression, optionalChainingExpression.expression)
                    if let index = expression.elements.index(of: element) {
                        newExpression.elements = newExpression.elements.with(\.[index], newElement)
                    }
                }

                let newPattern = PatternSyntax(pattern.with(\.expression, ExprSyntax(newExpression)))
                let newNode = node.with(\.pattern, newPattern)
                return super.visit(newNode)
            }

            return super.visit(node)
        }
    }
}

private extension TupleExprSyntax {
    func optionalChainingExpressions() -> [OptionalChainingExprSyntax] {
        elements
            .compactMap { $0.expression.as(OptionalChainingExprSyntax.self) }
            .filter { !$0.expression.isDiscardAssignmentOrBoolLiteral }
    }
}

private extension ExprSyntax {
    var isDiscardAssignmentOrBoolLiteral: Bool {
        `is`(DiscardAssignmentExprSyntax.self) || `is`(BooleanLiteralExprSyntax.self)
    }
}
