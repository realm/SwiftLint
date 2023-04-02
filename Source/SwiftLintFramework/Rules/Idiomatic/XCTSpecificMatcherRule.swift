import SwiftOperators
import SwiftSyntax

struct XCTSpecificMatcherRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

    static let description = RuleDescription(
        identifier: "xct_specific_matcher",
        name: "XCTest Specific Matcher",
        description: "Prefer specific XCTest matchers over `XCTAssertEqual` and `XCTAssertNotEqual`.",
        kind: .idiomatic,
        nonTriggeringExamples: XCTSpecificMatcherRuleExamples.nonTriggeringExamples,
        triggeringExamples: XCTSpecificMatcherRuleExamples.triggeringExamples
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension XCTSpecificMatcherRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FunctionCallExprSyntax) {
            if let suggestion = TwoArgsXCTAssert.violations(in: node) ?? OneArgXCTAssert.violations(in: node) {
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
        guard let name = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text,
              let matcher = Self(rawValue: name),
              let argument = node.argumentList.first?.expression.as(SequenceExprSyntax.self),
              let folded = try? OperatorTable.standardOperators.foldSingle(argument),
              let binOp = folded.as(InfixOperatorExprSyntax.self)?.operatorOperand.as(BinaryOperatorExprSyntax.self),
              let kind = Comparison(rawValue: binOp.operatorToken.text) else {
            return nil
        }
        return matcher.suggestion(for: kind)
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
        guard let name = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text,
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
        let arguments = node.argumentList
            .prefix(2)
            .map { $0.expression.trimmedDescription }
            .sorted { arg1, _ -> Bool in
                return protectedArguments.contains(arg1)
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
