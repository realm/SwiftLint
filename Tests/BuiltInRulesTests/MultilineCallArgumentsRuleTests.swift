// swiftlint:disable file_length
import Foundation
@testable import SwiftLintBuiltInRules
import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct MultilineCallArgumentsRuleTests {
    // MARK: - Reason tests

    @Test
    func reasonSingleLineMultipleArgumentsNotAllowed() throws {
        let violations = try validate(
            "foo(a: 1, b: 2)",
            config: ["allows_single_line": false]
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        )
    }

    @Test
    func reasonTooManyArgumentsOnASingleLine() throws {
        let max = 2
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: ["max_number_of_single_line_parameters": max]
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        )
    }

    @Test
    func reasonMultilineEachArgumentMustStartOnItsOwnLine() throws {
        let violations = try validate("""
            foo(
                a: 1, b: 2,
                c: 3
            )
            """
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        )
    }

    @Test
    func reasonMultilineEachArgumentMustStartOnItsOwnLineDetectsSameLineAfterNewline() throws {
        let violations = try validate("""
            foo(
                a: 1,
                b: 2, c: 3
            )
            """
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine
        )
    }

    @Test
    func reasonMultilineEachArgumentMustStartOnItsOwnLineDetectsMultipleViolations() throws {
        let violations = try validate("""
            foo(
                a: 1, b: 2,
                c: 3, d: 4
            )
            """
        )

        #expect(violations.count == 2)
        #expect(
            violations.allSatisfy { $0.reason == MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine }
        )
    }

    @Test
    func reasonMultilineRequiresNewlineAfterCommaInSplitLayout() throws {
        let violations = try validate("""
            foo(
                a: (
                    1,
                    2
                ), b: 3
            )
            """
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall
        )
    }

    @Test
    func reasonTooManyArgumentsOnASingleLineWorksWithTrailingClosure() throws {
        let max = 1
        let violations = try validate("""
            foo(a: 1, b: 2) { _ in
                print("x")
            }
            """,
            config: ["max_number_of_single_line_parameters": max]
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: max)
        )
    }

    @Test
    func reasonSingleLineNotAllowedHasPriorityOverMaxNumberOfSingleLineParameters() throws {
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ]
        )

        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed
        )
    }

    // MARK: - Auto-correction: no correction when comments present

    @Test
    func correctionWithCommentBetweenArgumentsDoesNotAutoCorrect() throws {
        let contents = "foo(a: 1, /* comment */ b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    @Test
    func correctionWithLineCommentBetweenArgumentsDoesNotAutoCorrect() throws {
        let contents = "foo(a: 1, // comment\n b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
    }

    @Test
    func correctionWithCommentAfterExpressionBeforeCommaDoesNotAutoCorrect() throws {
        let contents = "foo(a: 1 /* comment */, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    @Test
    func correctionWithCommentBetweenColonAndExpressionDoesNotAutoCorrect() throws {
        let contents = "foo(a: /* comment */ 1, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    @Test
    func correctionWithCommentBetweenLabelAndColonDoesNotAutoCorrect() throws {
        let contents = "foo(a /* comment */: 1, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    @Test
    func correctionWithCommentAfterLastArgExpressionDoesNotAutoCorrect() throws {
        let contents = "foo(a: 1, b: 2 /* comment */)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    @Test
    func correctionWithCommentInStringLiteralDoesAutoCorrect() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file1 = SwiftLintFile(contents: "foo(a: \"/* not a comment */\", b: 2)")
        #expect(rule.correct(file: file1) == 1)
        let file2 = SwiftLintFile(contents: "foo(a: \"/* not a comment */\", b: \"// also not\")")
        #expect(rule.correct(file: file2) == 1)
    }

    @Test
    func correctionMultilineWithCommentsDoesNotAutoCorrect() throws {
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let cases = [
            "foo(\n    a: 1, /* comment */ b: 2,\n    c: 3\n)",
            "foo(\n    a: 1 /* comment */, b: 2,\n    c: 3\n)",
            "foo(\n    a: (\n        1,\n        2\n    ), /* comment */ b: 3\n)",
        ]
        for contents in cases {
            let file = SwiftLintFile(contents: contents)
            #expect(rule.correct(file: file) == 0, "Should not correct: \(contents)")
        }
    }

    // MARK: - Configuration

    @Test
    func configurationInvalidValuesThrow() {
        #expect(throws: Issue.self) {
            _ = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": 0])
        }
        #expect(throws: Issue.self) {
            _ = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": -1])
        }
        #expect(throws: Issue.self) {
            _ = try MultilineCallArgumentsRule(configuration: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 2,
            ])
        }
    }

    @Test
    func configurationAllowsSingleLineFalseWithMaxParametersOneIsValid() {
        #expect(throws: Never.self) {
            _ = try MultilineCallArgumentsRule(configuration: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ])
        }
    }

    // MARK: - Edge cases

    @Test
    func correctionWithCRLFLineEndingsCorrectsIndentation() throws {
        let contents = "foo(\r\n    a: 1, b: 2,\r\n    c: 3\r\n)"
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(!file.contents.contains("\r "))
    }

    @Test
    func reasonNewlineAfterCommaViolationSkippedForArrayLiteralArgument() throws {
        let violations = try validate("""
            func foo(one: [Int], animated: Bool) {}
            add(one: [
                1,
                2,
                3
            ], animated: true)
            """)
        #expect(violations.isEmpty)
    }

    @Test
    func reasonNewlineAfterCommaViolationSkippedForClosureArgument() throws {
        let violations = try validate("""
            foo(with: {
                9_999
            }, and: {
                nil
            })
            """)
        #expect(violations.isEmpty)
    }

    @Test
    func reasonMixedDuplicateStartLineAndNewlineAfterComma() throws {
        let violations = try validate("""
            foo(
                a: 1, b: 2,
                c: (
                    3,
                    4
                ), d: 5
            )
            """)
        #expect(violations.count == 2)
        #expect(violations[0].reason == MultilineCallArgumentsRule.Reason.eachArgumentMustStartOnOwnLine)
        #expect(violations[1].reason == MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall)
    }

    @Test
    func reasonMultipleNewlineAfterCommaViolations() throws {
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
        #expect(violations.count == 2)
        #expect(violations.allSatisfy {
            $0.reason == MultilineCallArgumentsRule.Reason.newlineRequiredAfterCommaInMultilineCall
        })
    }

    @Test
    func violationPositionForUnlabeledArgument() throws {
        let violations = try validate("foo(1, 2)", config: ["allows_single_line": false])
        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.singleLineMultipleArgumentsNotAllowed)
    }

    @Test
    func violationPositionForMixedLabeledAndUnlabeledArguments() throws {
        let violations = try validate(
            "foo(1, b: 2, 3)",
            config: ["max_number_of_single_line_parameters": 1])
        #expect(violations.count == 1)
        #expect(
            violations.first?.reason == MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: 1))
    }

    @Test
    func patternMatchingPositionDoesNotViolate() throws {
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
        #expect(violations.isEmpty)
    }

    @Test
    func lineCacheMultipleCallsOnDifferentLinesViolationsHaveCorrectLineNumbers() throws {
        let contents = """
            foo(a: 1, b: 2, c: 3)
            bar(x: 1, y: 2, z: 3, w: 4)
            baz(1, 2, 3, 4, 5)
            """
        let violations = try validate(contents, config: ["max_number_of_single_line_parameters": 2])
        #expect(violations.count == 3)
        #expect(violations[0].location.line == 1)
        #expect(violations[1].location.line == 2)
        #expect(violations[2].location.line == 3)
    }

    // MARK: - Global indentation via CurrentRule

    @Test
    func correctionUsesGlobalTabIndentation() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        CurrentRule.$indentation.withValue(.tabs) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "foo(\n\ta: 1,\n\tb: 2\n)")
    }

    @Test
    func correctionUsesGlobal2SpaceIndentation() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        CurrentRule.$indentation.withValue(.spaces(count: 2)) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "foo(\n  a: 1,\n  b: 2\n)")
    }

    @Test
    func correctionFallsBackToDefaultIndentationWhenNotSet() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    a: 1,\n    b: 2\n)")
    }

    @Test
    func correctionMultilineUsesGlobalTabIndentation() throws {
        let contents = """
            foo(
                a: 1, b: 2,
                c: 3
            )
            """
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        CurrentRule.$indentation.withValue(.tabs) {
            #expect(rule.correct(file: file) == 1)
        }
        // Only the violation (b: 2 on same line as a: 1) is corrected;
        // existing indentation of a: 1 and c: 3 is preserved.
        #expect(file.contents == "foo(\n    a: 1,\n\tb: 2,\n    c: 3\n)")
    }

    // MARK: - getLineIndent edge cases

    @Test
    func correctionCallOnFirstLineHasNoBaseIndent() throws {
        let contents = "foo(a: 1, b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    a: 1,\n    b: 2\n)")
        #expect(!file.contents.hasPrefix(" "))
    }

    // MARK: - Deeply nested suppression

    @Test
    func correctionDeeplyNestedSuppressesInnermostCorrection() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "outer(middle(inner(1, 2), 3), 4)")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "outer(\n    middle(inner(1, 2), 3),\n    4\n)")
    }

    @Test
    func correctionDeeplyNestedThroughNonViolatingMiddleSuppressesInner() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "outer(single(middle(1, 2)), 3)")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "outer(\n    single(middle(1, 2)),\n    3\n)")
    }

    // MARK: - Helper

    private func validate(_ contents: String, config: [String: Any] = [:]) throws -> [StyleViolation] {
        let rule = try MultilineCallArgumentsRule(configuration: config)
        return rule.validate(file: SwiftLintFile(contents: contents))
    }
}

@Suite(.rulesRegistered)
struct MultilineCallArgumentsLinterTests {
    // MARK: - End-to-end: global indentation through Linter pipeline

    private func makeLinter(file: SwiftLintFile, indentation: IndentationStyle) throws -> CollectedLinter {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let config = Configuration(
            rulesMode: .onlyConfiguration(["multiline_call_arguments"]),
            allRulesWrapped: [(rule, false)],
            indentation: indentation
        )
        let storage = RuleStorage()
        return Linter(file: file, configuration: config).collect(into: storage)
    }

    @Test
    func linterCorrectionUsesGlobalTabIndentation() throws {
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        let linter = try makeLinter(file: file, indentation: .tabs)
        let storage = RuleStorage()
        let corrections = linter.correct(using: storage)
        #expect(corrections["multiline_call_arguments"] == 1)
        #expect(file.contents == "foo(\n\ta: 1,\n\tb: 2\n)")
    }

    @Test
    func linterCorrectionUsesGlobal2SpaceIndentation() throws {
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        let linter = try makeLinter(file: file, indentation: .spaces(count: 2))
        let storage = RuleStorage()
        let corrections = linter.correct(using: storage)
        #expect(corrections["multiline_call_arguments"] == 1)
        #expect(file.contents == "foo(\n  a: 1,\n  b: 2\n)")
    }

    @Test
    func linterCorrectionUsesDefault4SpaceIndentation() throws {
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        let linter = try makeLinter(file: file, indentation: .default)
        let storage = RuleStorage()
        let corrections = linter.correct(using: storage)
        #expect(corrections["multiline_call_arguments"] == 1)
        #expect(file.contents == "foo(\n    a: 1,\n    b: 2\n)")
    }
}

@Suite
struct IndentationStyleTests {
    @Test
    func initializationAndIndentationString() throws {
        let style = try IndentationStyle(fromAny: 4, context: "test_rule")
        #expect(style.indentationString == "    ")
        let tabStyle = try IndentationStyle(fromAny: "tabs", context: "test_rule")
        #expect(tabStyle.indentationString == "\t")
        #expect(IndentationStyle.spaces(count: 1).indentationString == " ")
        #expect(IndentationStyle.spaces(count: 2).indentationString == "  ")
        #expect(IndentationStyle.spaces(count: 8).indentationString == "        ")
    }

    @Test
    func invalidValueThrows() {
        #expect(throws: Issue.self) {
            _ = try IndentationStyle(fromAny: 0, context: "test_rule")
        }
        #expect(throws: Issue.self) {
            _ = try IndentationStyle(fromAny: -1, context: "test_rule")
        }
        #expect(throws: Issue.self) {
            _ = try IndentationStyle(fromAny: "spaces", context: "test_rule")
        }
        #expect(throws: Issue.self) {
            _ = try IndentationStyle(fromAny: 3.14, context: "test_rule")
        }
    }

    @Test
    func asOptionAndEquality() {
        #expect(IndentationStyle.spaces(count: 4).asOption() == .integer(4))
        #expect(IndentationStyle.tabs.asOption() == .string("tabs"))
        // swiftlint:disable:next identical_operands
        #expect(IndentationStyle.spaces(count: 4) == IndentationStyle.spaces(count: 4))
        #expect(IndentationStyle.spaces(count: 4) != IndentationStyle.spaces(count: 2))
        #expect(IndentationStyle.tabs != IndentationStyle.spaces(count: 4))
    }
}
