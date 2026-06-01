@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class MultilineCallArgumentsRuleTests: XCTestCase {
    func testReason_singleLineMultipleArgumentsNotAllowed() throws {
        let violations = try validate("foo(a: 1, b: 2)", config: ["allows_single_line": false])
        XCTAssertEqual(violations.count, 1)
        let reason = MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        XCTAssertEqual(violations.first?.reason, reason)
    }
    func testReason_tooManyArgumentsOnASingleLine() throws {
        let max = 2
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: ["max_number_of_single_line_parameters": max])
        XCTAssertEqual(violations.count, 1)
        let reason = MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        XCTAssertEqual(violations.first?.reason, reason)
    }
    func testReason_multilineEachArgumentMustStartOnItsOwnLine() throws {
        let reason = MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        let violations1 = try validate("foo(\n    a: 1, b: 2,\n    c: 3\n)")
        XCTAssertEqual(violations1.count, 1)
        XCTAssertEqual(violations1.first?.reason, reason)
        let violations2 = try validate("foo(\n    a: 1,\n    b: 2, c: 3\n)")
        XCTAssertEqual(violations2.count, 1)
        XCTAssertEqual(violations2.first?.reason, reason)
        let violations3 = try validate("foo(\n    a: 1, b: 2,\n    c: 3, d: 4\n)")
        XCTAssertEqual(violations3.count, 2)
        XCTAssertTrue(violations3.allSatisfy { $0.reason == reason })
    }
    func testReason_multilineRequiresNewlineAfterCommaInSplitLayout() throws {
        let violations = try validate("""
            foo(
                a: (
                    1,
                    2
                ), b: 3
            )
            """)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall)
    }
    func testReason_tooManyArgumentsOnASingleLine_worksWithTrailingClosure() throws {
        let max = 1
        let violations = try validate("""
            foo(a: 1, b: 2) { _ in
                print("x")
            }
            """,
            config: ["max_number_of_single_line_parameters": max])
        XCTAssertEqual(violations.count, 1)
        let reason = MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        XCTAssertEqual(violations.first?.reason, reason)
    }
    func testReason_singleLineNotAllowed_hasPriorityOverMaxNumberOfSingleLineParameters() throws {
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: ["allows_single_line": false, "max_number_of_single_line_parameters": 1])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed)
    }
}

// MARK: - Auto-correction with comments

extension MultilineCallArgumentsRuleTests {
    func testCorrection_withCommentBetweenArguments_doesNotAutoCorrect() throws {
        let contents = "foo(a: 1, /* comment */ b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 0)
        XCTAssertEqual(file.contents, contents)
    }
    func testCorrection_withLineCommentBetweenArguments_doesNotAutoCorrect() throws {
        let contents = "foo(a: 1, // comment\n b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 0)
    }
    func testCorrection_withCommentAfterExpressionBeforeComma_doesNotAutoCorrect() throws {
        let contents = "foo(a: 1 /* comment */, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 0)
        XCTAssertEqual(file.contents, contents)
    }
    func testCorrection_withCommentBetweenColonAndExpression_doesNotAutoCorrect() throws {
        let contents = "foo(a: /* comment */ 1, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 0)
        XCTAssertEqual(file.contents, contents)
    }
    func testCorrection_withCommentBetweenLabelAndColon_doesNotAutoCorrect() throws {
        let contents = "foo(a /* comment */: 1, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 0)
        XCTAssertEqual(file.contents, contents)
    }
    func testCorrection_withCommentAfterLastArgExpression_doesNotAutoCorrect() throws {
        let contents = "foo(a: 1, b: 2 /* comment */)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 0)
        XCTAssertEqual(file.contents, contents)
    }
    func testCorrection_withCommentInStringLiteral_doesAutoCorrect() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file1 = SwiftLintFile(contents: "foo(a: \"/* not a comment */\", b: 2)")
        XCTAssertEqual(rule.correct(file: file1), 1)
        let file2 = SwiftLintFile(contents: "foo(a: \"/* not a comment */\", b: \"// also not\")")
        XCTAssertEqual(rule.correct(file: file2), 1)
    }
    func testCorrection_singleLineCorrection_format() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "foo(\n    a: 1,\n    b: 2\n)")
        let rule2 = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": 2])
        let file2 = SwiftLintFile(contents: "foo(a: 1, b: 2, c: 3)")
        XCTAssertEqual(rule2.correct(file: file2), 1)
        XCTAssertTrue(file2.contents.contains("\n    a: 1,\n"))
        XCTAssertTrue(file2.contents.contains("\n    c: 3\n"))
    }
    func testCorrection_singleLineCorrection_customIndent() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false, "indentation": 2])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "foo(\n  a: 1,\n  b: 2\n)")
    }
    func testCorrection_multilineWithComments_doesNotAutoCorrect() throws {
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let cases = [
            "foo(\n    a: 1, /* comment */ b: 2,\n    c: 3\n)",
            "foo(\n    a: 1 /* comment */, b: 2,\n    c: 3\n)",
            "foo(\n    a: (\n        1,\n        2\n    ), /* comment */ b: 3\n)",
        ]
        for contents in cases {
            let file = SwiftLintFile(contents: contents)
            XCTAssertEqual(rule.correct(file: file), 0, "Should not correct: \(contents)")
        }
    }
    func testCorrection_multilineWithoutComments_doesAutoCorrect() throws {
        let contents = """
            foo(
                a: 1, b: 2,
                c: 3
            )
            """
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 1)
    }
    func testCorrection_multipleDuplicateStartLines_fixesAll() throws {
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let file = SwiftLintFile(contents: "foo(\n    a: 1, b: 2,\n    c: 3, d: 4\n)")
        XCTAssertEqual(rule.correct(file: file), 2)
        XCTAssertEqual(file.contents, "foo(\n    a: 1,\n    b: 2,\n    c: 3,\n    d: 4\n)")
    }
    func testCorrection_nestedSingleLineCall_suppressesInnerCorrection() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(bar(1, 2), baz: 3)")
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "foo(\n    bar(1, 2),\n    baz: 3\n)")
    }
    func testCorrection_nestedThroughNonViolatingOuter_suppressesInnerCorrection() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "grandFoo(singleArgFoo(bar(1, 2)), baz: 3)")
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "grandFoo(\n    singleArgFoo(bar(1, 2)),\n    baz: 3\n)")
    }
    func testCorrection_nestedWithMaxParameters_suppressesInnerCorrection() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": 2])
        let file = SwiftLintFile(contents: "foo(bar(1, 2, 3), baz: 4, qux: 5)")
        XCTAssertEqual(rule.correct(file: file), 1)
    }
    func testCorrection_nestedOuterWithComments_innerCorrectionAllowed() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(bar(1, 2) /* c */, baz: 3)")
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "foo(bar(\n    1,\n    2\n) /* c */, baz: 3)")
    }
    func testCorrection_deeplyNestedSingleLineCall_withSingleArgMiddleLayer_suppressesInnerCorrection() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "grandFoo(singleArgFoo(bar(1, 2)), baz: 3)")
        let count = rule.correct(file: file)
        print("Corrections: \(count)")
        print("Result: \(file.contents)")
        XCTAssertEqual(count, 1)
        XCTAssertEqual(file.contents, "grandFoo(\n    singleArgFoo(bar(1, 2)),\n    baz: 3\n)")
    }
    func testCorrection_singleLineCorrection_openParenOnNewLine() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(\n    a: 1, b: 2)")
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "foo(\n    a: 1,\n    b: 2\n)")
    }
}

// MARK: - IndentationStyle & Configuration

extension MultilineCallArgumentsRuleTests {
    func testIndentationStyle_initializationAndIndentationString() throws {
        let style = try IndentationStyle(fromAny: 4, context: "test_rule")
        XCTAssertEqual(style.indentationString, "    ")
        let tabStyle = try IndentationStyle(fromAny: "tab", context: "test_rule")
        XCTAssertEqual(tabStyle.indentationString, "\t")
        XCTAssertEqual(IndentationStyle.spaces(count: 1).indentationString, " ")
        XCTAssertEqual(IndentationStyle.spaces(count: 2).indentationString, "  ")
        XCTAssertEqual(IndentationStyle.spaces(count: 8).indentationString, "        ")
    }
    func testIndentationStyle_invalidValue_throws() {
        XCTAssertThrowsError(try IndentationStyle(fromAny: 0, context: "test_rule")) { error in
            if let issue = error as? Issue, case .invalidConfiguration(_, let message) = issue {
                XCTAssertTrue(message!.contains("indentation"))
            }
        }
        XCTAssertThrowsError(try IndentationStyle(fromAny: -1, context: "test_rule"))
        XCTAssertThrowsError(try IndentationStyle(fromAny: "spaces", context: "test_rule"))
        XCTAssertThrowsError(try IndentationStyle(fromAny: 3.14, context: "test_rule"))
    }
    func testIndentationStyle_asOptionAndEquality() {
        XCTAssertEqual(IndentationStyle.spaces(count: 4).asOption(), .integer(4))
        XCTAssertEqual(IndentationStyle.tab.asOption(), .string("tab"))
        XCTAssertEqual(IndentationStyle.spaces(count: 4), IndentationStyle.spaces(count: 4))
        XCTAssertNotEqual(IndentationStyle.spaces(count: 4), IndentationStyle.spaces(count: 2))
        XCTAssertNotEqual(IndentationStyle.tab, IndentationStyle.spaces(count: 4))
    }
    func testConfiguration_invalidValues_throw() {
        XCTAssertThrowsError(try MultilineCallArgumentsRule(configuration: ["indentation": 0]))
        XCTAssertThrowsError(try MultilineCallArgumentsRule(configuration: ["indentation": -2]))
        XCTAssertThrowsError(try MultilineCallArgumentsRule(configuration: ["indentation": "spaces"]))
        XCTAssertThrowsError(try MultilineCallArgumentsRule(
            configuration: ["max_number_of_single_line_parameters": 0]))
        XCTAssertThrowsError(try MultilineCallArgumentsRule(
            configuration: ["max_number_of_single_line_parameters": -1]))
        XCTAssertThrowsError(try MultilineCallArgumentsRule(configuration: [
            "allows_single_line": false,
            "max_number_of_single_line_parameters": 2,
        ]))
    }
    func testConfiguration_indentationTab_isValid() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["indentation": "tab"])
        XCTAssertEqual(rule.configuration.indentationStyle, .tab)
    }
    func testConfiguration_indentationInt_isValid() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["indentation": 2])
        XCTAssertEqual(rule.configuration.indentationStyle, .spaces(count: 2))
    }
    func testConfiguration_allowsSingleLineFalse_withMaxParametersOne_isValid() throws {
        XCTAssertNoThrow(
            try MultilineCallArgumentsRule(configuration: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ]))
    }
}

// MARK: - Edge cases

extension MultilineCallArgumentsRuleTests {
    func testCorrection_withCRLFLineEndings_correctsIndentation() throws {
        let contents = "foo(\n    a: 1, b: 2,\n    c: 3\n)".replacingOccurrences(of: "\n", with: "\r\n")
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertFalse(file.contents.contains("\r "))
    }
    func testReason_newlineAfterCommaViolation_skippedForArrayLiteralArgument() throws {
        let violations = try validate("""
            func foo(one: [Int], animated: Bool) {}
            add(one: [
                1,
                2,
                3
            ], animated: true)
            """)
        XCTAssertEqual(violations.count, 0)
    }
    func testReason_newlineAfterCommaViolation_skippedForClosureArgument() throws {
        let violations = try validate("""
            foo(with: {
                9_999
            }, and: {
                nil
            })
            """)
        XCTAssertEqual(violations.count, 0)
    }
    func testReason_mixedDuplicateStartLineAndNewlineAfterComma() throws {
        let violations = try validate("""
            foo(
                a: 1, b: 2,
                c: (
                    3,
                    4
                ), d: 5
            )
            """)
        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].reason, MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine)
        XCTAssertEqual(violations[1].reason, MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall)
    }
    func testReason_multipleNewlineAfterCommaViolations() throws {
        let violations = try validate("""
            foo(
                a: (
                    1,
                    2
                ), b: 3,
                c: (
                    4,
                    5
                ), d: 6
            )
            """)
        XCTAssertEqual(violations.count, 2)
        XCTAssertTrue(violations.allSatisfy {
            $0.reason == MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall
        })
    }
    func testViolationPosition_forUnlabeledArgument() throws {
        let violations = try validate("foo(1, 2)", config: ["allows_single_line": false])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed)
    }
    func testViolationPosition_forMixedLabeledAndUnlabeledArguments() throws {
        let violations = try validate(
            "foo(1, b: 2, 3)",
            config: ["max_number_of_single_line_parameters": 1])
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(
            violations.first?.reason,
            MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: 1))
    }
    func testPatternMatchingPosition_doesNotViolate() throws {
        let violations = try validate("""
            enum EnumCase { case caseOne(Int, Int, Int, Int) }
            if case .caseOne(1, 2, 3, 4) = EnumCase.caseOne(
                0,
                0,
                0,
                0
            ) {}
            """,
            config: ["max_number_of_single_line_parameters": 2])
        XCTAssertEqual(violations.count, 0)
    }
    func testLineCache_multipleCallsOnDifferentLines_violationsHaveCorrectLineNumbers() throws {
        let contents = """
            foo(a: 1, b: 2, c: 3)
            bar(x: 1, y: 2, z: 3, w: 4)
            baz(1, 2, 3, 4, 5)
            """
        let violations = try validate(contents, config: ["max_number_of_single_line_parameters": 2])
        XCTAssertEqual(violations.count, 3)
        XCTAssertEqual(violations[0].location.line, 1)
        XCTAssertEqual(violations[1].location.line, 2)
        XCTAssertEqual(violations[2].location.line, 3)
    }
    // getLineIndent(lineNumber:) guards against out-of-range values, returning "";
    // unreachable through public API — verified indirectly by baseIndent="" on line 1.
    func testCorrection_callOnFirstLine_noBaseIndent_usesOnlyConfiguredIndent() throws {
        let contents = "foo(a: 1, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        XCTAssertEqual(rule.correct(file: file), 1)
        XCTAssertEqual(file.contents, "foo(\n    a: 1,\n    b: 2\n)")
        XCTAssertFalse(file.contents.hasPrefix(" "))
    }
}

// MARK: - Helper

extension MultilineCallArgumentsRuleTests {
    private func validate(_ contents: String, config: [String: Any] = [:]) throws -> [StyleViolation] {
        let rule = try MultilineCallArgumentsRule(configuration: config)
        return rule.validate(file: SwiftLintFile(contents: contents))
    }
}
