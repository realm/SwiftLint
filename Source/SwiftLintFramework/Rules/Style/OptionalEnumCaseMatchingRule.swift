import SwiftSyntax

struct OptionalEnumCaseMatchingRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "optional_enum_case_matching",
        name: "Optional Enum Case Match",
        description: "Matching an enum case against an optional enum without '?' is supported on Swift 5.1 and above.",
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
            """, excludeFromDocumentation: true)
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
            """)
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
            """)
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension OptionalEnumCaseMatchingRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: CaseItemSyntax) {
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

    final class Rewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
        private(set) var correctionPositions: [AbsolutePosition] = []
        let locationConverter: SourceLocationConverter
        let disabledRegions: [SourceRange]

        init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
            self.locationConverter = locationConverter
            self.disabledRegions = disabledRegions
        }

        override func visit(_ node: CaseItemSyntax) -> CaseItemSyntax {
            guard
                let pattern = node.pattern.as(ExpressionPatternSyntax.self),
                pattern.expression.is(OptionalChainingExprSyntax.self) || pattern.expression.is(TupleExprSyntax.self),
                !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter)
            else {
                return super.visit(node)
            }

            if let expression = pattern.expression.as(OptionalChainingExprSyntax.self),
               !expression.expression.isDiscardAssignmentOrBoolLiteral {
                let violationPosition = expression.questionMark.positionAfterSkippingLeadingTrivia
                correctionPositions.append(violationPosition)
                let newExpression = ExprSyntax(expression.withQuestionMark(nil))
                let newPattern = PatternSyntax(pattern.withExpression(newExpression))
                let newNode = node
                    .withPattern(newPattern)
                    .withWhereClause(node.whereClause?.withLeadingTrivia(expression.questionMark.trailingTrivia))
                return super.visit(newNode)
            } else if let expression = pattern.expression.as(TupleExprSyntax.self) {
                var newExpression = expression
                for (index, element) in expression.elementList.enumerated() {
                    guard
                        let optionalChainingExpression = element.expression.as(OptionalChainingExprSyntax.self),
                        !optionalChainingExpression.expression.is(DiscardAssignmentExprSyntax.self)
                    else {
                        continue
                    }

                    let violationPosition = optionalChainingExpression.questionMark.positionAfterSkippingLeadingTrivia
                    correctionPositions.append(violationPosition)

                    let newElementExpression = ExprSyntax(optionalChainingExpression.withQuestionMark(nil))
                    let newElement = element.withExpression(newElementExpression)
                    newExpression.elementList = newExpression.elementList
                        .replacing(childAt: index, with: newElement)
                }

                let newPattern = PatternSyntax(pattern.withExpression(ExprSyntax(newExpression)))
                let newNode = node.withPattern(newPattern)
                return super.visit(newNode)
            }

            return super.visit(node)
        }
    }
}

private extension TupleExprSyntax {
    func optionalChainingExpressions() -> [OptionalChainingExprSyntax] {
        elementList
            .compactMap { $0.expression.as(OptionalChainingExprSyntax.self) }
            .filter { !$0.expression.isDiscardAssignmentOrBoolLiteral }
    }
}

private extension ExprSyntax {
    var isDiscardAssignmentOrBoolLiteral: Bool {
        `is`(DiscardAssignmentExprSyntax.self) || `is`(BooleanLiteralExprSyntax.self)
    }
}
