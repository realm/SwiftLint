@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class MultilineCallArgumentsRuleTests: XCTestCase {
    func testReason_singleLineMultipleArgumentsNotAllowed() throws {
        let violations = try validate(
            "foo(a: 1, b: 2)",
            config: ["allows_single_line": false]
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        )
    }

    func testReason_tooManyArgumentsOnASingleLine() throws {
        let max = 2
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: ["max_number_of_single_line_parameters": max]
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        )
    }

    func testReason_multilineEachArgumentMustStartOnItsOwnLine() throws {
        let violations = try validate("""
            foo(
                a: 1, b: 2,
                c: 3
            )
            """
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        )
    }

    func testReason_multilineEachArgumentMustStartOnItsOwnLine_detectsSameLineAfterNewline() throws {
        let violations = try validate("""
            foo(
                a: 1,
                b: 2, c: 3
            )
            """
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        )
    }

    func testReason_multilineRequiresNewlineAfterCommaInSplitLayout() throws {
        let violations = try validate("""
            foo(
                a: (
                    1,
                    2
                ), b: 3
            )
            """
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall
        )
    }

    func testReason_tooManyArgumentsOnASingleLine_worksWithTrailingClosure() throws {
        let max = 1
        let violations = try validate("""
            foo(a: 1, b: 2) { _ in
                print("x")
            }
            """,
            config: ["max_number_of_single_line_parameters": max]
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        )
    }

    func testReason_singleLineNotAllowed_hasPriorityOverMaxNumberOfSingleLineParameters() throws {
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ]
        )

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        )
    }

    // MARK: - Helper

    private func validate(_ contents: String, config: [String: Any] = [:]) throws -> [StyleViolation] {
        let rule = try MultilineCallArgumentsRule(configuration: config)
        return rule.validate(file: SwiftLintFile(contents: contents))
    }
}
