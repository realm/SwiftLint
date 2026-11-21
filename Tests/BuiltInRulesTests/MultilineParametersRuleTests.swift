// swiftlint:disable file_length

@testable import SwiftLintBuiltInRules
import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct MultilineParametersRuleTests {
    // MARK: - Reason tests

    @Test
    func reasonSingleLineNotAllowedHasPriorityOverMaxNumberOfSingleLineParameters() throws {
        let violations = try validate(
            "func foo(param1: Int, param2: Bool, param3: [String])",
            config: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ]
        )
        #expect(violations.count == 1)
        #expect(violations.first?.reason == MultilineParametersRule.Reason.singleLineMultipleParametersNotAllowed)
    }

    @Test
    func reasonTooManyParametersOnSingleLine() throws {
        let violations = try validate(
            "func foo(param1: Int, param2: Bool, param3: [String])",
            config: ["max_number_of_single_line_parameters": 2]
        )
        #expect(violations.count == 1)
        #expect(violations.first?.reason == MultilineParametersRule.Reason.tooManyParametersOnSingleLine(max: 2))
    }

    @Test
    func reasonMultilineEachParameterMustStartOnItsOwnLine() throws {
        let violations = try validate("""
            func foo(param1: Int,
                     param2: Bool, param3: [String]) { }
            """)
        #expect(violations.count == 1)
        #expect(violations.first?.reason == MultilineParametersRule.Reason.eachParameterMustStartOnOwnLine)
    }

    @Test
    func reasonMultilineMultipleViolations() throws {
        let violations = try validate("""
            func foo(
                param1: Int, param2: Bool,
                param3: Int, param4: [String]
            ) { }
            """)
        #expect(violations.count == 2)
        #expect(violations.allSatisfy {
            $0.reason == MultilineParametersRule.Reason.eachParameterMustStartOnOwnLine
        })
    }

    // MARK: - Auto-correction: single-line

    @Test
    func correctionSingleLineTooManyParameters() throws {
        let rule = try MultilineParametersRule(configuration: ["max_number_of_single_line_parameters": 2])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool, param3: [String]) { }")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "func foo(\n    param1: Int,\n    param2: Bool,\n    param3: [String]\n) { }")
    }

    @Test
    func correctionSingleLineWithThreeParamsNotAllowed() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool, param3: [String]) { }")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            func foo(
                param1: Int,
                param2: Bool,
                param3: [String]
            ) { }
            """)
    }

    // MARK: - Auto-correction: multi-line

    @Test
    func correctionMultilineTwoParamsOnSameLine() throws {
        let contents = """
            func foo(param1: Int,
                     param2: Bool, param3: [String]) { }
            """
        let rule = try MultilineParametersRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            func foo(
                param1: Int,
                param2: Bool,
                param3: [String]
            ) { }
            """)
    }

    @Test
    func correctionMultilineWithBracketsOnSeparateLines() throws {
        let contents = """
            func foo(
                param1: Int,
                param2: Bool, param3: [String]
            ) { }
            """
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            func foo(
                param1: Int,
                param2: Bool,
                param3: [String]
            ) { }
            """)
    }

    @Test
    func correctionMultilineBothPairsShareLine() throws {
        let contents = """
            func foo(
                param1: Int, param2: Bool,
                param3: Int, param4: [String]
            ) { }
            """
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            func foo(
                param1: Int,
                param2: Bool,
                param3: Int,
                param4: [String]
            ) { }
            """)
    }

    // MARK: - Auto-correction: init

    @Test
    func correctionInitSingleLinePreservesThrows() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "class Foo {\n    init(param1: Int, param2: Bool) throws { }\n}")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            class Foo {
                init(
                    param1: Int,
                    param2: Bool
                ) throws { }
            }
            """)
    }

    // MARK: - Auto-correction: nested indentation

    @Test
    func correctionNestedInClass() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "class Foo {\n    func foo(param1: Int, param2: Bool) { }\n}")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "class Foo {\n    func foo(\n        param1: Int,\n        param2: Bool\n    ) { }\n}")
    }

    // MARK: - Auto-correction: no correction when comments present

    @Test
    func correctionWithCommentsDoesNotAutoCorrect() throws {
        let contents = "func foo(param1: Int, /* comment */ param2: Bool) { }"
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    @Test
    func correctionMultilineWithCommentsDoesNotAutoCorrect() throws {
        let rule = try MultilineParametersRule(configuration: [:])
        let contents = "func foo(param1: Int,\n         param2: Bool, /* comment */ param3: [String]) { }"
        let file = SwiftLintFile(contents: contents)
        #expect(!rule.validate(file: file).isEmpty)
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == contents)
    }

    // MARK: - Auto-correction: idempotency

    @Test
    func correctionSingleLineIsIdempotent() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) { }")
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0, "second pass must not change a corrected declaration")
        #expect(file.contents == firstPass)
    }

    @Test
    func correctionMultilineIsIdempotent() throws {
        let contents = """
            func foo(
                param1: Int,
                param2: Bool, param3: [String]
            ) { }
            """
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        let firstPass = file.contents
        #expect(rule.correct(file: file) == 0)
        #expect(file.contents == firstPass)
    }

    // MARK: - Global indentation via CurrentRule.configuration

    @Test
    func correctionUsesGlobalTabIndentation() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) { }")
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "func foo(\n\tparam1: Int,\n\tparam2: Bool\n) { }")
    }

    @Test
    func correctionUsesGlobal2SpaceIndentation() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) { }")
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .spaces(count: 2))) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "func foo(\n  param1: Int,\n  param2: Bool\n) { }")
    }

    @Test
    func correctionNestedUsesGlobalTabIndentation() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "class Foo {\n    func foo(param1: Int, param2: Bool) { }\n}")
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        #expect(file.contents == "class Foo {\n    func foo(\n\t\tparam1: Int,\n\t\tparam2: Bool\n\t) { }\n}")
    }

    @Test
    func correctionMultilineUsesGlobalTabIndentation() throws {
        let contents = """
            func foo(
                param1: Int,
                param2: Bool, param3: [String]
            ) { }
            """
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: contents)
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .tabs)) {
            #expect(rule.correct(file: file) == 1)
        }
        // Full expansion: all params reindented to baseIndent (empty for column 0) + oneLevel (\t).
        #expect(file.contents == "func foo(\n\tparam1: Int,\n\tparam2: Bool,\n\tparam3: [String]\n) { }")
    }

    @Test
    func correctionSingleLineNormalizesSourceTabsToSpaces() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "class Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}")
        CurrentRule.$configuration.withValue(GlobalConfiguration(indentation: .spaces(count: 2))) {
            #expect(rule.correct(file: file) == 1)
        }
        // baseIndent normalizes 1 source tab to 1 level (2 spaces); oneLevel adds 2 more.
        // The original `\t` on the `func foo` line is preserved because only the parameter
        // clause is replaced — the rest of the line keeps its source indentation.
        #expect(file.contents == "class Foo {\n\tfunc foo(\n    param1: Int,\n    param2: Bool\n  ) { }\n}")
    }

    // MARK: - CRLF handling

    @Test
    func correctionSingleLineHandlesCRLF() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) { }\r\n")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "func foo(\n    param1: Int,\n    param2: Bool\n) { }\r\n")
    }

    @Test
    func correctionMultilineHandlesCRLF() throws {
        let contents = "func foo(param1: Int,\r\n         param2: Bool, param3: [String]) { }"
        let rule = try MultilineParametersRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "func foo(\n    param1: Int,\n    param2: Bool,\n    param3: [String]\n) { }")
    }

    // MARK: - Multi-line init correction

    @Test
    func correctionInitMultiline() throws {
        let contents = """
            class Foo {
                init(param1: Int, param2: Bool,
                     param3: @escaping ((Int) -> Void)? = { _ in }) { }
            }
            """
        let rule = try MultilineParametersRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            class Foo {
                init(
                    param1: Int,
                    param2: Bool,
                    param3: @escaping ((Int) -> Void)? = { _ in }
                ) { }
            }
            """)
    }

    // MARK: - Protocol multi-line violation

    @Test
    func correctionProtocolMultilineViolation() throws {
        let contents = "protocol Foo {\n    func foo(param1: Int,\n             param2: Bool, param3: [String])\n}"
        let rule = try MultilineParametersRule(configuration: [:])
        let file = SwiftLintFile(contents: contents)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            protocol Foo {
                func foo(
                    param1: Int,
                    param2: Bool,
                    param3: [String]
                )
            }
            """)
    }

    // MARK: - Deep nesting

    @Test
    func correctionDeeplyNestedInStructInClass() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: """
            class Outer {
                struct Inner {
                    func foo(param1: Int, param2: Bool) { }
                }
            }
            """)
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == """
            class Outer {
                struct Inner {
                    func foo(
                        param1: Int,
                        param2: Bool
                    ) { }
                }
            }
            """)
    }

    // MARK: - Configuration

    @Test
    func configurationAllowsSingleLineFalseWithMaxParametersOneIsValid() {
        #expect(throws: Never.self) {
            _ = try MultilineParametersRule(configuration: [
                "allows_single_line": false,
                "max_number_of_single_line_parameters": 1,
            ])
        }
    }

    // MARK: - Line cache: multiple functions on different lines

    @Test
    func lineCacheMultipleFunctionsOnDifferentLinesViolationsHaveCorrectLineNumbers() throws {
        let contents = """
            func foo(a: Int, b: Int, c: Int)
            func bar(x: Int, y: Int, z: Int, w: Int)
            func baz(p1: Int, p2: Int, p3: Int, p4: Int, p5: Int)
            """
        let violations = try validate(contents, config: ["max_number_of_single_line_parameters": 2])
        #expect(violations.count == 3)
        let sortedLines = violations.compactMap(\.location.line).sorted()
        #expect(sortedLines == [1, 2, 3])
    }

    // MARK: - Protocol function correction (no body)

    @Test
    func correctionProtocolFunction() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "protocol Foo {\n    func foo(param1: Int, param2: Bool)\n}")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "protocol Foo {\n    func foo(\n        param1: Int,\n        param2: Bool\n    )\n}")
    }

    // MARK: - max_number_of_single_line_parameters: 1

    @Test
    func reasonMaxOneEquivalentToAllowsSingleLineFalse() throws {
        let violations = try validate(
            "func foo(param1: Int, param2: Bool) { }",
            config: ["max_number_of_single_line_parameters": 1]
        )
        #expect(violations.count == 1)
        #expect(violations.first?.reason == MultilineParametersRule.Reason.tooManyParametersOnSingleLine(max: 1))
    }

    // MARK: - Async / throws / where clause preservation

    @Test
    func correctionPreservesAsyncThrowsAndReturnType() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) async throws -> Int { }")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "func foo(\n    param1: Int,\n    param2: Bool\n) async throws -> Int { }")
    }

    @Test
    func correctionPreservesWhereClause() throws {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let file = SwiftLintFile(contents: "func foo<T>(param1: Int, param2: Bool) where T: Comparable { }")
        #expect(rule.correct(file: file) == 1)
        #expect(file.contents == "func foo<T>(\n    param1: Int,\n    param2: Bool\n) where T: Comparable { }")
    }

    // MARK: - Helper

    private func validate(_ contents: String, config: [String: Any] = [:]) throws -> [StyleViolation] {
        let rule = try MultilineParametersRule(configuration: config)
        return rule.validate(file: SwiftLintFile(contents: contents))
    }
}

@Suite(.rulesRegistered)
struct MultilineParametersLinterTests {
    private func makeLinter(file: SwiftLintFile, indentation: IndentationStyle) throws -> CollectedLinter {
        let rule = try MultilineParametersRule(configuration: ["allows_single_line": false])
        let config = Configuration(
            rulesMode: .onlyConfiguration(["multiline_parameters"]),
            allRulesWrapped: [(rule, false)],
            indentation: indentation
        )
        let storage = RuleStorage()
        return Linter(file: file, configuration: config).collect(into: storage)
    }

    @Test
    func linterCorrectionUsesGlobalTabIndentation() throws {
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) { }")
        let linter = try makeLinter(file: file, indentation: .tabs)
        let storage = RuleStorage()
        let corrections = linter.correct(using: storage)
        #expect(corrections["multiline_parameters"] == 1)
        #expect(file.contents == "func foo(\n\tparam1: Int,\n\tparam2: Bool\n) { }")
    }

    @Test
    func linterCorrectionUsesGlobal2SpaceIndentation() throws {
        let file = SwiftLintFile(contents: "func foo(param1: Int, param2: Bool) { }")
        let linter = try makeLinter(file: file, indentation: .spaces(count: 2))
        let storage = RuleStorage()
        let corrections = linter.correct(using: storage)
        #expect(corrections["multiline_parameters"] == 1)
        #expect(file.contents == "func foo(\n  param1: Int,\n  param2: Bool\n) { }")
    }
}
