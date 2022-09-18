import SwiftSyntax
import SwiftSyntaxBuilder

private func wrapInSwitch(
    variable: String = "foo",
    _ str: String,
    file: StaticString = #file, line: UInt = #line) -> Example {
    return Example(
        """
        switch \(variable) {
        \(str): break
        }
        """, file: file, line: line)
}

private func wrapInFunc(_ str: String, file: StaticString = #file, line: UInt = #line) -> Example {
    return Example("""
    func example(foo: Foo) {
        switch foo {
        case \(str):
            break
        }
    }
    """, file: file, line: line)
}

public struct EmptyEnumArgumentsRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_enum_arguments",
        name: "Empty Enum Arguments",
        description: "Arguments can be omitted when matching enums with associated values if they are not used.",
        kind: .style,
        nonTriggeringExamples: [
            wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar(let x)"),
            wrapInSwitch("case let .bar(x)"),
            wrapInSwitch(variable: "(foo, bar)", "case (_, _)"),
            wrapInSwitch("case \"bar\".uppercased()"),
            wrapInSwitch(variable: "(foo, bar)", "case (_, _) where !something"),
            wrapInSwitch("case (let f as () -> String)?"),
            wrapInSwitch("default"),
            Example("if case .bar = foo {\n}"),
            Example("guard case .bar = foo else {\n}"),
            Example("if foo == .bar() {}"),
            Example("guard foo == .bar() else { return }"),
            Example("""
            if case .appStore = self.appInstaller, !UIDevice.isSimulator() {
                viewController.present(self, animated: false)
            } else {
                UIApplication.shared.open(self.appInstaller.url)
            }
            """)
        ],
        triggeringExamples: [
            wrapInSwitch("case .bar↓(_)"),
            wrapInSwitch("case .bar↓()"),
            wrapInSwitch("case .bar↓(_), .bar2↓(_)"),
            wrapInSwitch("case .bar↓() where method() > 2"),
            wrapInFunc("case .bar↓(_)"),
            Example("if case .bar↓(_) = foo {\n}"),
            Example("guard case .bar↓(_) = foo else {\n}"),
            Example("if case .bar↓() = foo {\n}"),
            Example("guard case .bar↓() = foo else {\n}"),
            Example("""
            if case .appStore↓(_) = self.appInstaller, !UIDevice.isSimulator() {
                viewController.present(self, animated: false)
            } else {
                UIApplication.shared.open(self.appInstaller.url)
            }
            """)
        ],
        corrections: [
            wrapInSwitch("case .bar↓(_)"): wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar↓()"): wrapInSwitch("case .bar"),
            wrapInSwitch("case .bar↓(_), .bar2↓(_)"): wrapInSwitch("case .bar, .bar2"),
            wrapInSwitch("case .bar↓() where method() > 2"): wrapInSwitch("case .bar where method() > 2"),
            wrapInFunc("case .bar↓(_)"): wrapInFunc("case .bar"),
            Example("if case .bar↓(_) = foo {"): Example("if case .bar = foo {"),
            Example("guard case .bar↓(_) = foo else {"): Example("guard case .bar = foo else {")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor()
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        file.locationConverter.map { locationConverter in
            Rewriter(
                locationConverter: locationConverter,
                disabledRegions: disabledRegions(file: file)
            )
        }
    }
}

private extension EmptyEnumArgumentsRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: CaseItemSyntax) {
            if let violationPosition = node.pattern.emptyEnumArgumentsViolation(rewrite: false)?.position {
                violationPositions.append(violationPosition)
            }
        }

        override func visitPost(_ node: MatchingPatternConditionSyntax) {
            if let violationPosition = node.pattern.emptyEnumArgumentsViolation(rewrite: false)?.position {
                violationPositions.append(violationPosition)
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

        override func visit(_ node: CaseItemSyntax) -> Syntax {
            guard
                let (violationPosition, newPattern) = node.pattern.emptyEnumArgumentsViolation(rewrite: true),
                !isInDisabledRegion(node)
            else {
                return super.visit(node)
            }

            correctionPositions.append(violationPosition)
            return super.visit(Syntax(node.withPattern(newPattern)))
        }

        override func visit(_ node: MatchingPatternConditionSyntax) -> Syntax {
            guard
                let (violationPosition, newPattern) = node.pattern.emptyEnumArgumentsViolation(rewrite: true),
                !isInDisabledRegion(node)
            else {
                return super.visit(node)
            }

            correctionPositions.append(violationPosition)
            return super.visit(Syntax(node.withPattern(newPattern)))
        }

        private func isInDisabledRegion<T: SyntaxProtocol>(_ node: T) -> Bool {
            disabledRegions.contains { region in
                region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
            }
        }
    }
}

private extension PatternSyntax {
    func emptyEnumArgumentsViolation(rewrite: Bool) -> (position: AbsolutePosition, pattern: PatternSyntax)? {
        guard
            var pattern = self.as(ExpressionPatternSyntax.self),
            let expression = pattern.expression.as(FunctionCallExprSyntax.self),
            expression.argumentList.allSatisfy({ $0.expression.is(DiscardAssignmentExprSyntax.self) }),
            let calledExpression = expression.calledExpression.as(MemberAccessExprSyntax.self),
            calledExpression.base == nil,
            let violationPosition = expression.leftParen?.positionAfterSkippingLeadingTrivia
        else {
            return nil
        }

        if rewrite {
            let newCalledExpression = calledExpression
                .withTrailingTrivia(expression.rightParen?.trailingTrivia ?? .zero)
            let newExpression = expression
                .withCalledExpression(ExprSyntax(newCalledExpression))
                .withLeftParen(nil)
                .withArgumentList(nil)
                .withRightParen(nil)
            pattern.expression = ExprSyntax(newExpression)
        }

        return (violationPosition, PatternSyntax(pattern))
    }
}
