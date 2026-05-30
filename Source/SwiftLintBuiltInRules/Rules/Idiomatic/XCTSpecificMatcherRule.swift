import SwiftOperators
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct XCTSpecificMatcherRule: Rule {
    var configuration = XCTSpecificMatcherConfiguration()

    static let description = RuleDescription(
        identifier: "xct_specific_matcher",
        name: "XCTest Specific Matcher",
        description: "Prefer specific XCTest matchers.",
        rationale: """
        Using specific matchers like `XCTAssertEqual`, `XCTAssertNotEqual`, `XCTAssertTrue`, `XCTAssertFalse`,
        `XCTAssertIdentical` and `XCTAssertNotIdentical` improves code readability and clarity. They more clearly
        state the intention of the assertion.

        Consider for example `XCTAssertTrue(foo == bar)`, which requires two details to grasp: that `foo` and `bar`
        are equal, and that the result of the comparison shall be true. Using `XCTAssertEqual(foo, bar)` makes it
        clear that the intention is to check equality, without needing to understand the underlying logic of the
        comparison.
        """,
        kind: .idiomatic,
        nonTriggeringExamples: XCTSpecificMatcherRuleExamples.nonTriggeringExamples,
        triggeringExamples: XCTSpecificMatcherRuleExamples.triggeringExamples
    )
}

private extension XCTSpecificMatcherRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        private lazy var optionalBoolBindings = OptionalBoolBindingsCollector.bindings(in: file)

        override func visitPost(_ node: FunctionCallExprSyntax) {
            if configuration.matchers.contains(.twoArgumentAsserts),
               let suggestion = TwoArgsXCTAssert.violations(
                   in: node,
                   optionalBoolBindings: optionalBoolBindings
               ) {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Prefer the specific matcher '\(suggestion)' instead"
                ))
            } else if configuration.matchers.contains(.oneArgumentAsserts),
                      let suggestion = OneArgXCTAssert.violations(in: node) {
                violations.append(ReasonedRuleViolation(
                    position: node.positionAfterSkippingLeadingTrivia,
                    reason: "Prefer the specific matcher '\(suggestion)' instead"
                ))
            }
        }
    }
}

private enum OneArgXCTAssert: String {
    case assert = "XCTAssert"
    case `true` = "XCTAssertTrue"
    case `false` = "XCTAssertFalse"

    private enum Comparison: String {
        case equal = "=="
        case unequal = "!="
        case identical = "==="
        case notIdentical = "!=="
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func suggestion(for comparisonOperator: Comparison) -> String {
        switch (self, comparisonOperator) {
        case (.assert, .equal): "XCTAssertEqual"
        case (.true, .equal): "XCTAssertEqual"
        case (.assert, .unequal): "XCTAssertNotEqual"
        case (.true, .unequal): "XCTAssertNotEqual"
        case (.false, .equal): "XCTAssertNotEqual"
        case (.false, .unequal): "XCTAssertEqual"
        case (.assert, .identical): "XCTAssertIdentical"
        case (.true, .identical): "XCTAssertIdentical"
        case (.assert, .notIdentical): "XCTAssertNotIdentical"
        case (.true, .notIdentical): "XCTAssertNotIdentical"
        case (.false, .identical): "XCTAssertNotIdentical"
        case (.false, .notIdentical): "XCTAssertIdentical"
        }
    }

    static func violations(in node: FunctionCallExprSyntax) -> String? {
        guard let name = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              let matcher = Self(rawValue: name),
              let argument = node.arguments.first?.expression.as(SequenceExprSyntax.self),
              let folded = try? OperatorTable.standardOperators.foldSingle(argument),
              let operatorExpr = folded.as(InfixOperatorExprSyntax.self),
              let binOp = operatorExpr.operator.as(BinaryOperatorExprSyntax.self),
              let kind = Comparison(rawValue: binOp.operator.text),
              accept(operand: operatorExpr.leftOperand), accept(operand: operatorExpr.rightOperand) else {
            return nil
        }
        return matcher.suggestion(for: kind)
    }

    private static func accept(operand: ExprSyntax) -> Bool {
        // Check if the expression could be a type object like `String.self`. Note, however, that `1.self`
        // is also valid Swift. There is no way to be sure here.
        if operand.as(MemberAccessExprSyntax.self)?.declName.baseName.text == "self" {
            return false
        }
        if operand.as(TupleExprSyntax.self)?.elements.count ?? 0 > 1 {
            return false
        }
        return true
    }
}

private enum TwoArgsXCTAssert: String {
    case equal = "XCTAssertEqual"
    case notEqual = "XCTAssertNotEqual"

    private static let protectedArguments: Set<String> = [
        "false", "true", "nil"
    ]

    private func suggestion(for protectedArgument: String, hasOptional: Bool) -> String? {
        switch (self, protectedArgument, hasOptional) {
        case (.equal, "true", false): return "XCTAssertTrue"
        case (.equal, "false", false): return "XCTAssertFalse"
        case (.equal, "nil", _): return "XCTAssertNil"
        case (.notEqual, "true", false): return "XCTAssertFalse"
        case (.notEqual, "false", false): return "XCTAssertTrue"
        case (.notEqual, "nil", _): return "XCTAssertNotNil"
        default: return nil
        }
    }

    static func violations(in node: FunctionCallExprSyntax, optionalBoolBindings: Set<String>) -> String? {
        guard let name = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              let matcher = Self(rawValue: name) else {
            return nil
        }

        let twoArguments = Array(node.arguments.prefix(2))
        guard twoArguments.count == 2 else {
            return nil
        }

        let firstDescription = twoArguments[0].expression.trimmedDescription
        let secondDescription = twoArguments[1].expression.trimmedDescription

        let protectedArgument: String
        let otherExpression: ExprSyntax

        if protectedArguments.contains(firstDescription) {
            protectedArgument = firstDescription
            otherExpression = twoArguments[1].expression
        } else if protectedArguments.contains(secondDescription) {
            protectedArgument = secondDescription
            otherExpression = twoArguments[0].expression
        } else {
            return nil
        }

        let hasOptional = isOptionalExpression(
            otherExpression,
            optionalBoolBindings: optionalBoolBindings
        )

        guard let suggestedMatcher = matcher.suggestion(
            for: protectedArgument,
            hasOptional: hasOptional
        ) else {
            return nil
        }
        return suggestedMatcher
    }

    private static func isOptionalExpression(
        _ expression: ExprSyntax,
        optionalBoolBindings: Set<String>
    ) -> Bool {
        if expression.is(OptionalChainingExprSyntax.self) {
            return true
        }
        if let forceUnwrap = expression.as(ForceUnwrapExprSyntax.self) {
            return isOptionalExpression(forceUnwrap.expression, optionalBoolBindings: optionalBoolBindings)
        }
        if expression.trimmedDescription.contains("?") {
            return true
        }
        return referencesOptionalBoolBinding(expression, bindings: optionalBoolBindings)
    }

    private static func referencesOptionalBoolBinding(
        _ expression: ExprSyntax,
        bindings: Set<String>
    ) -> Bool {
        if let memberAccess = expression.as(MemberAccessExprSyntax.self) {
            if let base = memberAccess.base,
               referencesOptionalBoolBinding(base, bindings: bindings) {
                return true
            }
            return bindings.contains(memberAccess.declName.baseName.text)
        }
        if let declReference = expression.as(DeclReferenceExprSyntax.self) {
            return bindings.contains(declReference.baseName.text)
        }
        return false
    }
}

private enum OptionalBoolBindingsCollector {
    static func bindings(in file: SwiftLintFile) -> Set<String> {
        let visitor = Visitor(viewMode: .sourceAccurate)
        visitor.walk(file.syntaxTree)
        return visitor.bindings
    }

    private final class Visitor: SyntaxVisitor {
        private(set) var bindings = Set<String>()

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            for binding in node.bindings {
                guard let type = binding.typeAnnotation?.type, type.isOptionalBoolType else {
                    continue
                }
                bindings.formUnion(binding.pattern.optionalBindingNames)
            }
            return .skipChildren
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            if let returnType = node.signature.returnClause?.type, returnType.isOptionalBoolType {
                bindings.insert(node.name.text)
            }
            return .skipChildren
        }
    }
}

private extension TypeSyntax {
    var isOptionalBoolType: Bool {
        if let optionalType = self.as(OptionalTypeSyntax.self) {
            return optionalType.wrappedType.representsBoolType
        }
        if let implicitOptional = self.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return implicitOptional.wrappedType.representsBoolType
        }
        return false
    }

    var representsBoolType: Bool {
        if let identifierType = self.as(IdentifierTypeSyntax.self) {
            return identifierType.name.text == "Bool"
        }
        return false
    }
}

private extension PatternSyntax {
    var optionalBindingNames: Set<String> {
        if let identifierPattern = self.as(IdentifierPatternSyntax.self) {
            return [identifierPattern.identifier.text]
        }
        return []
    }
}
