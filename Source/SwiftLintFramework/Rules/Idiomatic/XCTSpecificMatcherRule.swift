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
        private static let protectedArguments: Set<String> = [
            "false", "true", "nil"
        ]

        override func visitPost(_ node: FunctionCallExprSyntax) {
            guard let name = node.calledExpression.as(IdentifierExprSyntax.self)?.identifier.text,
                  let matcher = XCTestMatcher(rawValue: name) else {
                return
            }

            /*
             *  - Gets the first two arguments and creates an array where the protected
             *    word is the first one (if any).
             *
             *  Examples:
             *
             *  - XCTAssertEqual(foo, true) -> [true, foo]
             *  - XCTAssertEqual(true, foo) -> [true, foo]
             *  - XCTAssertEqual(foo, true, "toto") -> [true, foo]
             *  - XCTAssertEqual(1, 2, accuracy: 0.1, "toto") -> [1, 2]
             */
            let arguments = node.argumentList
                .prefix(2)
                .map { $0.expression.withoutTrivia().description }
                .sorted { arg1, _ -> Bool in
                    return Self.protectedArguments.contains(arg1)
                }

            /*
             *  - Checks if the number of arguments is two (otherwise there's no need to continue).
             *  - Checks if the first argument is a protected word (otherwise there's no need to continue).
             *  - Gets the suggestion for the given protected word (taking in consideration the presence of
             *    optionals.
             *
             *  Examples:
             *
             *  - equal, [true, foo.bar] -> XCTAssertTrue
             *  - equal, [true, foo?.bar] -> no violation
             *  - equal, [nil, foo.bar] -> XCTAssertNil
             *  - equal, [nil, foo?.bar] -> XCTAssertNil
             *  - equal, [1, 2] -> no violation
             */
            guard arguments.count == 2,
                  let argument = arguments.first, Self.protectedArguments.contains(argument),
                  let hasOptional = arguments.last?.contains("?"),
                  let suggestedMatcher = matcher.suggestion(for: argument, hasOptional: hasOptional) else {
                return
            }

            violations.append(ReasonedRuleViolation(
                position: node.positionAfterSkippingLeadingTrivia,
                reason: "Prefer the specific matcher '\(suggestedMatcher)' instead"
            ))
        }
    }
}

private enum XCTestMatcher: String {
    case equal = "XCTAssertEqual"
    case notEqual = "XCTAssertNotEqual"

    func suggestion(for protectedArgument: String, hasOptional: Bool) -> String? {
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
}
