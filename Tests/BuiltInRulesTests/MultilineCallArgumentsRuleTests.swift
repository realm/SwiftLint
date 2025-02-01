@testable import SwiftLintBuiltInRules
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct MultilineCallArgumentsRuleTests {
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

    // MARK: - Helper

    private func validate(_ contents: String, config: [String: Any] = [:]) throws -> [StyleViolation] {
        let rule = try MultilineCallArgumentsRule(configuration: config)
        return rule.validate(file: SwiftLintFile(contents: contents))
    }
}
