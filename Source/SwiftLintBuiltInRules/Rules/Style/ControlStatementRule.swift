@_spi(SyntaxTransformVisitor)
import SwiftSyntax

@SwiftSyntaxRule
struct ControlStatementRule: ConfigurationProviderRule, SwiftSyntaxCorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "control_statement",
        name: "Control Statement",
        description:
            "`if`, `for`, `guard`, `switch`, `while`, and `catch` statements shouldn't unnecessarily wrap their " +
            "conditionals or arguments in parentheses",
        kind: .style,
        nonTriggeringExamples: [
            Example("if condition {}"),
            Example("if (a, b) == (0, 1) {}"),
            Example("if (a || b) && (c || d) {}"),
            Example("if (min...max).contains(value) {}"),
            Example("if renderGif(data) {}"),
            Example("renderGif(data)"),
            Example("guard condition else {}"),
            Example("while condition {}"),
            Example("do {} while condition {}"),
            Example("do { ; } while condition {}"),
            Example("switch foo {}"),
            Example("do {} catch let error as NSError {}"),
            Example("foo().catch(all: true) {}"),
            Example("if max(a, b) < c {}"),
            Example("switch (lhs, rhs) {}"),
            Example("if (f() { g() {} }) {}"),
            Example("if (a + f() {} == 1) {}")
        ],
        triggeringExamples: [
            Example("↓if (condition) {}"),
            Example("↓if(condition) {}"),
            Example("↓if (condition == endIndex) {}"),
            Example("↓if ((a || b) && (c || d)) {}"),
            Example("↓if ((min...max).contains(value)) {}"),
            Example("↓guard (condition) else {}"),
            Example("↓while (condition) {}"),
            Example("↓while(condition) {}"),
            Example("do { ; } ↓while(condition) {}"),
            Example("do { ; } ↓while (condition) {}"),
            Example("↓switch (foo) {}"),
            Example("do {} ↓catch(let error as NSError) {}"),
            Example("↓if (max(a, b) < c) {}")
        ],
        corrections: [
            Example("↓if (condition) {}"): Example("if condition {}"),
            Example("↓if(condition) {}"): Example("if condition {}"),
            Example("↓if (condition == endIndex) {}"): Example("if condition == endIndex {}"),
            Example("↓if ((a || b) && (c || d)) {}"): Example("if (a || b) && (c || d) {}"),
            Example("↓if ((min...max).contains(value)) {}"): Example("if (min...max).contains(value) {}"),
            Example("↓guard (condition) else {}"): Example("guard condition else {}"),
            Example("↓while (condition) {}"): Example("while condition {}"),
            Example("↓while(condition) {}"): Example("while condition {}"),
            Example("do {} ↓while (condition) {}"): Example("do {} while condition {}"),
            Example("do {} ↓while(condition) {}"): Example("do {} while condition {}"),
            Example("do { ; } ↓while(condition) {}"): Example("do { ; } while condition {}"),
            Example("do { ; } ↓while (condition) {}"): Example("do { ; } while condition {}"),
            Example("↓switch (foo) {}"): Example("switch foo {}"),
            Example("do {} ↓catch(let error as NSError) {}"): Example("do {} catch let error as NSError {}"),
            Example("↓if (max(a, b) < c) {}"): Example("if max(a, b) < c {}"),
            Example("""
            if (a),
               ( b == 1 ) {}
            """): Example("""
                if a,
                   b == 1 {}
                """)
        ]
    )

    func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
        Rewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

private extension ControlStatementRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override var skippableDeclarations: [any DeclSyntaxProtocol.Type] { [ProtocolDeclSyntax.self] }

        override func visitPost(_ node: CatchClauseSyntax) {
            if node.catchItems.containSuperfluousParens == true {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: GuardStmtSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: IfExprSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: SwitchExprSyntax) {
            if node.subject.unwrapped != nil {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: WhileStmtSyntax) {
            if node.conditions.containSuperfluousParens {
                violations.append(node.positionAfterSkippingLeadingTrivia)
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

        override func visit(_ node: CatchClauseSyntax) -> CatchClauseSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                  case let items = node.catchItems, items.containSuperfluousParens == true else {
                return super.visit(node)
            }
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let node = node
                .with(\.catchKeyword, node.catchKeyword.with(\.trailingTrivia, .space))
                .with(\.catchItems, items.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                  node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let node = node
                .with(\.guardKeyword, node.guardKeyword.with(\.trailingTrivia, .space))
                .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: IfExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                  node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let node = node
                .with(\.ifKeyword, node.ifKeyword.with(\.trailingTrivia, .space))
                .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }

        override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                  let tupleElement = node.subject.unwrapped else {
                return super.visit(node)
            }
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let node = node
                .with(\.switchKeyword, node.switchKeyword.with(\.trailingTrivia, .space))
                .with(\.subject, tupleElement.with(\.trailingTrivia, .space))
            return super.visit(node)
        }

        override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
            guard !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
                  node.conditions.containSuperfluousParens else {
                return super.visit(node)
            }
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            let node = node
                .with(\.whileKeyword, node.whileKeyword.with(\.trailingTrivia, .space))
                .with(\.conditions, node.conditions.withoutParens)
            return super.visit(node)
        }
    }
}

private class TrailingClosureFinder: SyntaxTransformVisitor {
    func visitAny(_ node: Syntax) -> Bool {
        false
    }

    func visit(_ node: FunctionCallExprSyntax) -> Bool {
        node.trailingClosure != nil
    }

    func visit(_ node: SequenceExprSyntax) -> Bool {
        node.elements.contains(where: visit)
    }
}

private extension ExprSyntax {
    var unwrapped: ExprSyntax? {
        if let expr = self.as(TupleExprSyntax.self)?.elements.onlyElement?.expression {
            return TrailingClosureFinder().visit(expr) ? nil : expr
        }
        return nil
    }
}

private extension ConditionElementListSyntax {
    var containSuperfluousParens: Bool {
        contains {
            if case let .expression(wrapped) = $0.condition {
                return wrapped.unwrapped != nil
            }
            return false
        }
    }

    var withoutParens: Self {
        let conditions = map { (element: ConditionElementSyntax) -> ConditionElementSyntax in
            if let expression = element.condition.as(ExprSyntax.self)?.unwrapped {
                return element
                    .with(\.condition, .expression(expression))
                    .with(\.leadingTrivia, element.leadingTrivia)
                    .with(\.trailingTrivia, element.trailingTrivia)
            }
            return element
        }
        return Self(conditions)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }
}

private extension CatchItemListSyntax {
    var containSuperfluousParens: Bool {
        contains { $0.unwrapped != nil }
    }

    var withoutParens: Self {
        let items = map { (item: CatchItemSyntax) -> CatchItemSyntax in
            if let expression = item.unwrapped {
                return item
                    .with(\.pattern, PatternSyntax(ExpressionPatternSyntax(expression: expression)))
                    .with(\.leadingTrivia, item.leadingTrivia)
                    .with(\.trailingTrivia, item.trailingTrivia)
            }
            return item
        }
        return Self(items)
            .with(\.leadingTrivia, leadingTrivia)
            .with(\.trailingTrivia, trailingTrivia)
    }
}

private extension CatchItemSyntax {
    var unwrapped: ExprSyntax? {
        pattern?.as(ExpressionPatternSyntax.self)?.expression.unwrapped
    }
}
