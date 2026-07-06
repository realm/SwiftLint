// swiftlint:disable file_length

@testable import SwiftLintBuiltInRules
import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct MultilineCallArgumentsRuleTests {
    // MARK: - Reason tests

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
    func reasonTooManyArgumentsOnSingleLine() throws {
        let violations = try validate(
            "foo(a: 1, b: 2, c: 3)",
            config: ["max_number_of_single_line_parameters": 2]
        )
        #expect(violations.count == 1)
        #expect(violations.first?.reason == MultilineCallArgumentsRule.Reason.tooManyArgumentsOnSingleLine(max: 2))
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
    func correctionWithCommentBetweenLabelAndColonDoesNotAutoCorrect() throws {
        let contents = "foo(a /* comment */: 1, b: 2)"
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
            #expect(!rule.validate(file: file).isEmpty, "violations must be reported: \(contents)")
            #expect(rule.correct(file: file) == 0, "Should not correct: \(contents)")
            #expect(file.contents == contents)
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

    // MARK: - Line cache: multiple calls on different lines

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

    // MARK: - Global indentation via CurrentRule.configuration

    @Test
    func correctionUsesGlobalTabIndentation() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "foo(\n\ta: 1,\n\tb: 2\n)")
    }

    @Test
    func correctionUsesGlobal2SpaceIndentation() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .spaces(count: 2))) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "foo(\n  a: 1,\n  b: 2\n)")
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
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        // Only the violation (b: 2 on same line as a: 1) is corrected;
        // existing indentation of a: 1 and c: 3 is preserved.
        #expect(file.contents == "foo(\n    a: 1,\n\tb: 2,\n    c: 3\n)")
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

    @Test
    func correctionDeeplyNestedWithMaxSuppressesInner() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["max_number_of_single_line_parameters": 2])
        let file = SwiftLintFile(contents: "outer(middle(1, 2, 3), 4, 5)")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "outer(\n    middle(1, 2, 3),\n    4,\n    5\n)")
    }

    // MARK: - Full expansion (first arg glued to `(`, last arg stranded with `)`)

    @Test
    func correctionFullyExpandsWhenFirstArgGluedAndLastArgStranded() throws {
        let contents = "foo(bar(\n    a: 1,\n    b: 2\n), c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    bar(\n        a: 1,\n        b: 2\n    ),\n    c: 3\n)")
    }

    @Test
    func correctionFullyExpandedUsesGlobalTabIndentation() throws {
        let contents = "foo(bar(\n\ta: 1,\n\tb: 2\n), c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "foo(\n\tbar(\n\t\ta: 1,\n\t\tb: 2\n\t),\n\tc: 3\n)")
    }

    @Test
    func correctionFullyExpandedIsIdempotent() throws {
        let contents = "foo(bar(\n    a: 1,\n    b: 2\n), c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0, "second pass must not change a corrected call")
        #expect(file.contents == firstPass)
    }

    @Test
    func correctionFullyExpandedWorksWithUnlabeledArguments() throws {
        let contents = "foo(bar(\n    1,\n    2\n), 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    bar(\n        1,\n        2\n    ),\n    3\n)")
    }

    // MARK: - Stranded `)` with first arg on its own line (closeParen branch)

    @Test
    func correctionCloseParenMovesLastArgAndParen() throws {
        let contents = "foo(\n    a: bar(\n        1\n    ), b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    a: bar(\n        1\n    ),\n    b: 2\n)")
    }

    @Test
    func correctionCloseParenUsesGlobalTabIndentation() throws {
        let contents = "foo(\n\ta: bar(\n\t\t1\n\t), b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "foo(\n\ta: bar(\n\t\t1\n\t),\n\tb: 2\n)")
    }

    @Test
    func correctionCloseParenWithUnlabeledArgs() throws {
        let contents = "foo(\n    bar(\n        1\n    ), 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    bar(\n        1\n    ),\n    2\n)")
    }

    @Test
    func correctionFullyExpandedHandlesCRLF() throws {
        let contents = "foo(bar(\r\n    a: 1,\r\n    b: 2\r\n), c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    bar(\n        a: 1,\n        b: 2\n    ),\n    c: 3\n)")
    }

    @Test
    func correctionCloseParenHandlesCRLF() throws {
        let contents = "foo(\r\n    a: bar(\r\n        1\r\n    ), b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\r\n    a: bar(\r\n        1\r\n    ),\n    b: 2\n)")
    }

    // MARK: - 3+ arguments: no data loss and idempotent convergence

    @Test
    func correctionThreeArgsDoesNotDropMiddleArguments() throws {
        let contents = "foo(a: bar(\n    1\n), b: 2, c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        // Correct to convergence: no pass may drop an argument.
        var remaining = 5
        while remaining > 0, rule.correct(file: file) > 0 {
            remaining -= 1
        }
        // All three original argument labels must still be present.
        #expect(file.contents.contains("a: bar("))
        #expect(file.contents.contains("b: 2"))
        #expect(file.contents.contains("c: 3"))
        // Exact converged output.
        #expect(file.contents == "foo(a: bar(\n    1\n),\n    b: 2,\n    c: 3)")
        // Converged: another pass produces no corrections.
        #expect(rule.correct(file: file) == 0)
    }

    // MARK: - Pattern matching: nested call inside a pattern constructor

    @Test
    func nestedCallInsidePatternIsNotLinted() throws {
        let contents = """
            enum Outer { case foo(Inner) }
            enum Inner { case bar(Int, Int, Int) }
            func test(_ x: Outer) {
                if case .foo(.bar(1, 2, 3)) = x {}
            }
            """
        let violations = try validate(contents, config: ["max_number_of_single_line_parameters": 2])
        #expect(violations.isEmpty, "inner `.bar(1, 2, 3)` is part of the pattern, not a call to lint")
    }

    // MARK: - closeParen branch: 3+ arguments and idempotency

    @Test
    func correctionCloseParenWithThreeArgsMovesLastArgAndParen() throws {
        let contents = "foo(\n    a: 1,\n    b: bar(\n        2\n    ), c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    a: 1,\n    b: bar(\n        2\n    ),\n    c: 3\n)")
    }

    @Test
    func correctionCloseParenIsIdempotent() throws {
        let contents = "foo(\n    a: bar(\n        1\n    ), b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0, "second pass must not change a corrected call")
        #expect(file.contents == firstPass)
    }

    // MARK: - Idempotency of standard corrections

    @Test
    func correctionSingleLineIsIdempotent() throws {
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "foo(a: 1, b: 2)")
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0, "second pass must not change a corrected call")
        #expect(file.contents == firstPass)
    }

    @Test
    func correctionNewlineAfterCommaIsIdempotent() throws {
        let contents = """
            foo(
                a: 1,
                b: 2, c: 3
            )
            """
        let rule = try MultilineCallArgumentsRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0, "second pass must not change a corrected call")
        #expect(file.contents == firstPass)
    }

    // MARK: - Multi-line closure argument reindentation

    @Test
    func correctionSingleLineWithMultilineClosureReindentsInnerLines() throws {
        let contents = "foo(a: 1, b: {\n    x\n})"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    a: 1,\n    b: {\n        x\n    }\n)")
    }

    @Test
    func correctionSingleLineWithMultilineClosureIsIdempotent() throws {
        let contents = "foo(a: 1, b: {\n    x\n})"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0, "second pass must not change a corrected call")
        #expect(file.contents == firstPass)
    }

    // MARK: - Full expansion with labeled first argument

    @Test
    func correctionFullyExpandedWithLabeledFirstArg() throws {
        let contents = "foo(a: bar(\n    1\n), b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    a: bar(\n        1\n    ),\n    b: 2\n)")
    }

    @Test
    func correctionFullyExpandedHandlesPureCR() throws {
        let contents = "foo(bar(\r    a: 1,\r    b: 2\r), c: 3)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\n    bar(\n        a: 1,\n        b: 2\n    ),\n    c: 3\n)")
    }

    @Test
    func correctionCloseParenHandlesPureCR() throws {
        let contents = "foo(\r    a: bar(\r        1\r    ), b: 2)"
        let rule = try MultilineCallArgumentsRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "foo(\r    a: bar(\r        1\r    ),\n    b: 2\n)")
    }

    // MARK: - closingTokensThatSkipNewlineAfterComma: rightBrace (multiline)

    @Test
    func rightBraceSkipMultilineDoesNotViolate() throws {
        let contents = """
            foo(
                a: {
                    x in x
                }, b: 2
            )
            """
        let violations = try validate(contents, config: ["allows_single_line": false])
        #expect(violations.isEmpty, "argument ending with `}` must skip newline-after-comma check")
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
}
