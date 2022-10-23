import SwiftSyntax

public struct ControlStatementRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description:
            "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their " +
            "conditionals or arguments in parentheses.",
        kind: .style,
        nonTriggeringExamples: [
            Example("if condition {}\n"),
            Example("if (a, b) == (0, 1) {}\n"),
            Example("if (a || b) && (c || d) {}\n"),
            Example("if (min...max).contains(value) {}\n"),
            Example("if renderGif(data) {}\n"),
            Example("renderGif(data)\n"),
            Example("for item in collection {}\n"),
            Example("for (key, value) in dictionary {}\n"),
            Example("for (index, value) in enumerate(array) {}\n"),
            Example("guard condition else {\n"),
            Example("while condition {}\n"),
            Example("do { ; } while condition {}\n"),
            Example("""
            switch foo {
            default: break
            }
            """),
            Example("do {\n} catch let error as NSError {\n}"),
            Example("foo().catch(all: true) {}"),
            Example("if max(a, b) < c {}\n"),
            Example("switch (lhs, rhs) {}\n")
        ],
        triggeringExamples: [
            Example("if ↓(condition) {}\n"),
            Example("if↓(condition) {}\n"),
            Example("if ↓(condition == endIndex) {}\n"),
            Example("if ↓((a || b) && (c || d)) {}\n"),
            Example("if ↓((min...max).contains(value)) {}\n"),
            Example("for ↓(item) in collection {}\n"),
            Example("guard ↓(condition) else { return }\n"),
            Example("while ↓(condition) {}\n"),
            Example("while↓(condition) {}\n"),
            Example("do { ; } while↓(condition) {\n"),
            Example("do { ; } while ↓(condition) {\n"),
            Example("""
            switch ↓(foo) {
            default: break
            }
            """),
            Example("do {} catch↓(let error as NSError) {}\n"),
            Example("if ↓(max(a, b) < c) {}\n"),
            Example("if ↓(list.contains { $0.id == 1 }) {}")
        ],
        corrections: [
            Example("if ↓(condition) {}\n"): Example("if condition {}\n"),
            Example("if↓(condition) {}\n"): Example("if condition {}\n"),
            Example("if ↓(condition == endIndex) {}\n"): Example("if condition == endIndex {}\n"),
            Example("if ↓((a || b) && (c || d)) {}\n"): Example("if (a || b) && (c || d) {}\n"),
            Example("if ↓((min...max).contains(value)) {}\n"): Example("if (min...max).contains(value) {}\n"),
            Example("for ↓(item) in collection {}\n"): Example("for item in collection {}\n"),
            Example("guard ↓(condition) else {}\n"): Example("guard condition else {}\n"),
            Example("while ↓(condition) {}\n"): Example("while condition {}\n"),
            Example("while↓(condition) {}\n"): Example("while condition {}\n"),
            Example("do { ; } while↓(condition) {}\n"): Example("do { ; } while condition {}\n"),
            Example("do { ; } while ↓(condition) {}\n"): Example("do { ; } while condition {}\n"),
            Example("""
            switch ↓(foo) {
            default: break
            }
            """): Example("""
            switch foo {
            default: break
            }
            """),
            Example("do {} catch↓(let error as NSError) {}"): Example("do {} catch let error as NSError {}"),
            Example("if ↓(max(a, b) < c) {}\n"): Example("if max(a, b) < c {}\n"),
            Example("if (list.contains { $0.id == 1 }) {}"): Example("if (list.contains { $0.id == 1 }) {}")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }

    public func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ControlStatementRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: ConditionElementSyntax) {
            if let tuple = node.condition.as(TupleExprSyntax.self), tuple.elementList.count == 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ExpressionPatternSyntax) {
            if let tuple = node.expression.as(TupleExprSyntax.self), tuple.elementList.count == 1 {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: SwitchStmtSyntax) {
            if let tuple = node.expression.as(TupleExprSyntax.self), tuple.elementList.count == 1 {
                violations.append(node.expression.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: ForInStmtSyntax) {
            if let pattern = node.pattern.as(TuplePatternSyntax.self), pattern.elements.count == 1 {
                violations.append(pattern.positionAfterSkippingLeadingTrivia)
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

        override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
            guard let tuple = node.condition.as(TupleExprSyntax.self), tuple.elementList.count == 1,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            let containsClosure = ClosureSyntaxVisitor(viewMode: .sourceAccurate)
                .walk(tree: node.condition, handler: \.containsClosure)
            guard !containsClosure else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)

            let condition = tuple.elementList.first?
                .as(ConditionElementSyntax.Condition.self)?
                .withLeadingTrivia(node.condition.updatedLeadingTrivia)
                .withTrailingTrivia(node.condition.trailingTrivia ?? .zero)

            let newNode = node.withCondition(condition)
            return super.visit(newNode)
        }

        override func visit(_ node: ExpressionPatternSyntax) -> PatternSyntax {
            guard let tuple = node.expression.as(TupleExprSyntax.self), tuple.elementList.count == 1,
               !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let newNode = node.withExpression(
                tuple.elementList.first?.expression
                    .withLeadingTrivia(node.expression.updatedLeadingTrivia)
                    .withTrailingTrivia(node.expression.trailingTrivia ?? .zero)
            )
            return super.visit(newNode)
        }

        override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
            guard let tuple = node.expression.as(TupleExprSyntax.self), tuple.elementList.count == 1,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(node.expression.positionAfterSkippingLeadingTrivia)
            let newNode = node.withExpression(
                tuple.elementList.first?.expression
                    .withLeadingTrivia(node.expression.updatedLeadingTrivia)
                    .withTrailingTrivia(node.expression.trailingTrivia ?? .zero)
            )
            return super.visit(newNode)
        }

        override func visit(_ node: ForInStmtSyntax) -> StmtSyntax {
            guard let pattern = node.pattern.as(TuplePatternSyntax.self), pattern.elements.count == 1,
                  !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter) else {
                return super.visit(node)
            }

            correctionPositions.append(pattern.positionAfterSkippingLeadingTrivia)
            let newNode = node.withPattern(
                pattern.elements.first?.pattern
                    .withLeadingTrivia(node.pattern.updatedLeadingTrivia)
                    .withTrailingTrivia(node.pattern.trailingTrivia ?? .zero)
            )
            return super.visit(newNode)
        }
    }
}

private class ClosureSyntaxVisitor: SyntaxVisitor {
    private(set) var containsClosure = false

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        containsClosure = true
        return .skipChildren
    }
}

private extension SyntaxProtocol {
    var updatedLeadingTrivia: Trivia {
        let leadingTrivia = leadingTrivia ?? .zero
        guard leadingTrivia.isEmpty, let previousToken = previousToken else {
            return leadingTrivia
        }

        if previousToken.trailingTrivia.isNotEmpty {
            return leadingTrivia
        }

        return .space
    }
}
