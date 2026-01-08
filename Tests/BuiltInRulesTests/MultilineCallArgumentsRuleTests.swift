@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class MultilineCallArgumentsRuleTests: XCTestCase {
    func testReason_singleLineMultipleArgumentsNotAllowed() throws {
        let rule = try makeRule(["allows_single_line": false])
        let violations = validate(rule, contents: "foo(a: 1, b: 2)")

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        )
    }

    func testReason_tooManyArgumentsOnASingleLine() throws {
        let max = 2
        let rule = try makeRule(["max_number_of_single_line_parameters": max])
        let violations = validate(rule, contents: "foo(a: 1, b: 2, c: 3)")

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        )
    }

    func testReason_multilineEachArgumentMustStartOnItsOwnLine() throws {
        let rule = try makeRule(["max_number_of_single_line_parameters": 10])
        let violations = validate(rule, contents: """
        foo(
            a: 1, b: 2,
            c: 3
        )
        """)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        )
    }

    func testReason_tooManyArgumentsOnASingleLine_worksWithTrailingClosure() throws {
        let max = 1
        let rule = try makeRule(["max_number_of_single_line_parameters": max])
        let violations = validate(rule, contents: """
        foo(a: 1, b: 2) { _ in
            print("x")
        }
        """)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        )
    }

    func testReason_singleLineNotAllowed_hasPriorityOverMaxNumberOfSingleLineParameters() throws {
        let rule = try makeRule([
            "allows_single_line": false,
            "max_number_of_single_line_parameters": 1,
        ])

        let violations = validate(rule, contents: "foo(a: 1, b: 2, c: 3)")

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        )
    }

    func testReason_multilineEachArgumentMustStartOnItsOwnLine_detectsSameLineAfterNewline() throws {
        let rule = try makeRule(["max_number_of_single_line_parameters": 10])
        let violations = validate(rule, contents: """
        foo(
            a: 1,
            b: 2, c: 3
        )
        """)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        )
    }

    // MARK: - Helpers

    private func makeRule(_ config: [String: Any]) throws -> MultilineCallArgumentsRule {
        try MultilineCallArgumentsRule(configuration: config)
    }

    private func validate(_ rule: some Rule, contents: String) -> [StyleViolation] {
        let file = SwiftLintFile(contents: contents)
        return rule.validate(file: file)
    }
}
