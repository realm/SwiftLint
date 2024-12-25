import SwiftOperators
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct XCTSpecificMatcherRule: Rule {
    var configuration = XCTSpecificMatcherConfiguration()

    static let description = RuleDescription(
        identifier: "xct_specific_matcher",
        name: "XCTest Specific Matcher",
        description: "Prefer specific XCTest matchers over `XCTAssertEqual` and `XCTAssertNotEqual`.",
        kind: .idiomatic,
        nonTriggeringExamples: XCTSpecificMatcherRuleExamples.nonTriggeringExamples,
        triggeringExamples: XCTSpecificMatcherRuleExamples.triggeringExamples
    )
}

private extension XCTSpecificMatcherRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if configuration.matchers.contains(.twoArgumentAsserts),
               let suggestion = TwoArgsXCTAssert.violations(in: node) {
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
    }

    private func suggestion(for comparisonOperator: Comparison) -> String {
        switch (self, comparisonOperator) {
        case (.assert, .equal):  return "XCTAssertEqual"
        case (.true, .equal):  return "XCTAssertEqual"
        case (.assert, .unequal):  return "XCTAssertNotEqual"
        case (.true, .unequal):  return "XCTAssertNotEqual"
        case (.false, .equal):  return "XCTAssertNotEqual"
        case (.false, .unequal):  return "XCTAssertEqual"
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

    static func violations(in node: FunctionCallExprSyntax) -> String? {
        guard let name = node.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text,
              let matcher = Self(rawValue: name) else {
            return nil
        }

        //
        //  - Gets the first two arguments and creates an array where the protected
        //    word is the first one (if any).
        //
        //  Examples:
        //
        //  - XCTAssertEqual(foo, true) -> [true, foo]
        //  - XCTAssertEqual(true, foo) -> [true, foo]
        //  - XCTAssertEqual(foo, true, "toto") -> [true, foo]
        //  - XCTAssertEqual(1, 2, accuracy: 0.1, "toto") -> [1, 2]
        //
        let arguments = node.arguments
            .prefix(2)
            .map(\.expression.trimmedDescription)
            .sorted { arg1, _ -> Bool in
                protectedArguments.contains(arg1)
            }

        //
        //  - Checks if the number of arguments is two (otherwise there's no need to continue).
        //  - Checks if the first argument is a protected word (otherwise there's no need to continue).
        //  - Gets the suggestion for the given protected word (taking in consideration the presence of
        //    optionals.
        //
        //  Examples:
        //
        //  - equal, [true, foo.bar] -> XCTAssertTrue
        //  - equal, [true, foo?.bar] -> no violation
        //  - equal, [nil, foo.bar] -> XCTAssertNil
        //  - equal, [nil, foo?.bar] -> XCTAssertNil
        //  - equal, [1, 2] -> no violation
        //
        guard arguments.count == 2,
              let argument = arguments.first, protectedArguments.contains(argument),
              let hasOptional = arguments.last?.contains("?"),
              let suggestedMatcher = matcher.suggestion(for: argument, hasOptional: hasOptional) else {
            return nil
        }
        return suggestedMatcher
    }
}
