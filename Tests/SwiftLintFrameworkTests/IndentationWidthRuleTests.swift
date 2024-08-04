@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import SwiftLintTestHelpers
import XCTest

final class IndentationWidthRuleTests: SwiftLintTestCase {
    func testInvalidIndentation() throws {
        var testee = IndentationWidthConfiguration()
        let defaultValue = testee.indentationWidth

        for indentation in [0, -1, -5] {
            XCTAssertEqual(
                try Issue.captureConsole { try testee.apply(configuration: ["indentation_width": indentation]) },
                "warning: Invalid configuration for 'indentation_width' rule. Falling back to default."
            )
            // Value remains the default.
            XCTAssertEqual(testee.indentationWidth, defaultValue)
        }
    }

    /// It's not okay to have the first line indented.
    func testFirstLineIndentation() async {
        await assert1Violation(in: "    firstLine")
        await assert1Violation(in: "   firstLine")
        await assert1Violation(in: " firstLine")
        await assert1Violation(in: "\tfirstLine")

        await assertNoViolation(in: "firstLine")
    }

    /// It's not okay to indent using both tabs and spaces in one line.
    func testMixedTabSpaceIndentation() async {
        // Expect 2 violations as secondLine is also indented by 8 spaces (which isn't valid)
        await assertViolations(in: "firstLine\n\t    secondLine", equals: 2)
        await assertViolations(in: "firstLine\n    \tsecondLine", equals: 2)
    }

    /// It's okay to indent using either tabs or spaces in different lines.
    func testMixedTabsAndSpacesIndentation() async {
        await assertNoViolation(in: "firstLine\n\tsecondLine\n        thirdLine")
        await assertNoViolation(in: "firstLine\n    secondLine\n\t\tthirdLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n        thirdLine\n\t\t\tfourthLine")
    }

    /// It's okay to keep the same indentation.
    func testKeepingIndentation() async {
        await assertNoViolation(in: "firstLine\nsecondLine")
        await assertNoViolation(in: "firstLine    \nsecondLine\n    thirdLine")
        await assertNoViolation(in: "firstLine\t\nsecondLine\n\tthirdLine")
    }

    /// It's only okay to indent using one tab or indentationWidth spaces.
    func testIndentationLength() async {
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 1)
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 2)
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 3)
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 4)
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 5)
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 6)
        await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 7)
        await assert1Violation(in: "firstLine\n\t\tsecondLine")
        await assert1Violation(in: "firstLine\n\t\t\tsecondLine")
        await assert1Violation(in: "firstLine\n\t\t\t\t\t\tsecondLine")

        await assertNoViolation(in: "firstLine\n\tsecondLine")
        await assertNoViolation(in: "firstLine\n secondLine", indentationWidth: 1)
        await assertNoViolation(in: "firstLine\n  secondLine", indentationWidth: 2)
        await assertNoViolation(in: "firstLine\n   secondLine", indentationWidth: 3)
        await assertNoViolation(in: "firstLine\n    secondLine", indentationWidth: 4)
        await assertNoViolation(in: "firstLine\n     secondLine", indentationWidth: 5)
        await assertNoViolation(in: "firstLine\n      secondLine", indentationWidth: 6)
        await assertNoViolation(in: "firstLine\n       secondLine", indentationWidth: 7)
        await assertNoViolation(in: "firstLine\n        secondLine", indentationWidth: 8)
    }

    /// It's okay to unindent indentationWidth * (1, 2, 3, ...) - x iff x == 0.
    func testUnindentation() async {
        await assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n fourthLine")
        await assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n  fourthLine")
        await assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n   fourthLine")
        await assert1Violation(in: "firstLine\n    secondLine\n    thirdLine\n   fourthLine")

        await assertNoViolation(in: "firstLine\n    secondLine\n        thirdLine\nfourthLine")
        await assertNoViolation(in: "firstLine\n    secondLine\n    thirdLine\nfourthLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n\t\tthirdLine\n\t\t\tfourthLine\nfifthLine")
    }

    /// It's okay to have empty lines between iff the following indentations obey the rules.
    func testEmptyLinesBetween() async {
        await assertNoViolation(in: "firstLine\n\tsecondLine\n\n\tfourthLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n \n\tfourthLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n           \n\tfourthLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n\n    fourthLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n \n    fourthLine")
        await assertNoViolation(in: "firstLine\n\tsecondLine\n           \n    fourthLine")

        await assert1Violation(in: "firstLine\n\tsecondLine\n\n\t\t\tfourthLine")
        await assert1Violation(in: "firstLine\n\tsecondLine\n \n\t\t\tfourthLine")
        await assert1Violation(in: "firstLine\n\tsecondLine\n           \n\t\t\tfourthLine")
        await assert1Violation(in: "firstLine\n\tsecondLine\n\n            fourthLine")
        await assert1Violation(in: "firstLine\n\tsecondLine\n \n            fourthLine")
        await assert1Violation(in: "firstLine\n\tsecondLine\n           \n            fourthLine")
    }

    func testsBrackets() async {
        await assertNoViolation(
            in: "firstLine\n    [\n        .thirdLine\n    ]\nfifthLine",
            includeComments: true
        )

        await assertNoViolation(
            in: "firstLine\n    [\n        .thirdLine\n    ]\nfifthLine",
            includeComments: false
        )

        await assertNoViolation(
            in: "firstLine\n    (\n        .thirdLine\n    )\nfifthLine",
            includeComments: true
        )

        await assertNoViolation(
            in: "firstLine\n    (\n        .thirdLine\n    )\nfifthLine",
            includeComments: false
        )
    }

    /// It's okay to have comments not following the indentation pattern iff the configuration allows this.
    func testCommentLines() async {
        await assert1Violation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            includeComments: true
        )
        await assertViolations(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n // test\n//test\n\t\tfourthLine",
            equals: 2,
            includeComments: true
        )
        await assertViolations(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n/*test\n  bad indent...\n test*/\n\t\tfourthLine",
            equals: 3,
            includeComments: true
        )

        await assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            includeComments: false
        )
        await assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n // test\n//test\n\t\tfourthLine",
            includeComments: false
        )
        await assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n/*test\n  bad indent...\n test*/\n\t\tfourthLine",
            includeComments: false
        )
    }

    /// Duplicate warnings for one actual indentation issue should be avoided.
    func testDuplicateWarningAvoidanceMechanism() async {
        // thirdLine is indented correctly, yet not in-line with the badly indented secondLine. This should be allowed.
        await assert1Violation(in: "firstLine\n secondLine\nthirdLine")

        // thirdLine is indented correctly, yet not in-line with the badly indented secondLine. This should be allowed.
        await assert1Violation(in: "firstLine\n     secondLine\n    thirdLine")

        // thirdLine is indented badly, yet in-line with the badly indented secondLine. This should be allowed.
        await assert1Violation(in: "firstLine\n     secondLine\n     thirdLine")

        // This pattern should go on indefinitely...
        await assert1Violation(in: "firstLine\n     secondLine\n     thirdLine\n    fourthLine")
        await assert1Violation(in: "firstLine\n     secondLine\n     thirdLine\n     fourthLine")

        // Still, this won't disable multiple line warnings in one file if suitable...
        await assertViolations(in: "firstLine\n     secondLine\nthirdLine\n     fourthLine", equals: 2)
        await assertViolations(in: "firstLine\n     secondLine\n    thirdLine\n     fourthLine", equals: 2)
        await assertViolations(in: "firstLine\n     secondLine\n     thirdLine\nfourthLine\n     fifthLine", equals: 2)
        await assertViolations(
            in: "firstLine\n     secondLine\n     thirdLine\n    fourthLine\n     fifthLine",
            equals: 2
        )
    }

    func testIgnoredCompilerDirectives() async {
        await assertNoViolation(in: """
            struct S {
                            #if os(iOS)
                var i: Int = 0
            #endif
                var j: Int = 0

                func reset() {
                #if os(iOS)
                    i = 0
                            #endif
                    j = 0
                }
            }
            """, includeCompilerDirectives: false)

        await assertNoViolation(in: """
            struct S {
                #if os(iOS)
                    var i: Int = 0
                #endif
                var j: Int = 0

                func reset() {
                    #if os(iOS)
                        i = 0
                    #endif
                    j = 0
                }
            }
            """, includeCompilerDirectives: true)
    }

    func testIncludeMultilineStrings() async {
        let example0 = #"""
            let x = """
                string1
                    string2
                  string3
                """
            """#
        await assertNoViolation(in: example0, includeMultilineStrings: false)
        await assert1Violation(in: example0, includeMultilineStrings: true)

        let example1 = #"""
            let x = """
                string1
                    string2
                  string3
                 string4
                """
            """#
        await assertNoViolation(in: example1, includeMultilineStrings: false)
        await assertViolations(in: example1, equals: 2, includeMultilineStrings: true)

        let example2 = ##"""
            let x = #"""
                string1
               """#
            """##
        await assert1Violation(in: example2, includeMultilineStrings: false)
        await assert1Violation(in: example2, includeMultilineStrings: true)

        let example3 = """
            let x = [
                "key": [
                    ["nestedKey": "string"],
                ],
            ]
            """
        await assertNoViolation(in: example3, includeMultilineStrings: false)
        await assertNoViolation(in: example3, includeMultilineStrings: true)

        let example4 = #"""
            func test() -> String {
                """
                ▿ Type:
                  - property: \(123) + \(456)
                \(true)
                """
            }
            """#
        await assertNoViolation(in: example4, includeMultilineStrings: false)
        await assert1Violation(in: example4, includeMultilineStrings: true)
    }

    // MARK: Helpers
    private func countViolations(
        in example: Example,
        indentationWidth: Int? = nil,
        includeComments: Bool = true,
        includeCompilerDirectives: Bool = true,
        includeMultilineStrings: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Int {
        var configDict: [String: Any] = [:]
        if let indentationWidth {
            configDict["indentation_width"] = indentationWidth
        }
        configDict["include_comments"] = includeComments
        configDict["include_compiler_directives"] = includeCompilerDirectives
        configDict["include_multiline_strings"] = includeMultilineStrings

        guard let config = makeConfig(configDict, IndentationWidthRule.description.identifier) else {
            XCTFail("Unable to create rule configuration.", file: (file), line: line)
            return 0
        }

        return await violations(example.with(code: example.code + "\n"), config: config).count
    }

    private func assertViolations(
        in string: String,
        equals expectedCount: Int,
        indentationWidth: Int? = nil,
        includeComments: Bool = true,
        includeCompilerDirectives: Bool = true,
        includeMultilineStrings: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await AsyncAssertEqual(
            await countViolations(
                in: Example(string, file: (file), line: line),
                indentationWidth: indentationWidth,
                includeComments: includeComments,
                includeCompilerDirectives: includeCompilerDirectives,
                includeMultilineStrings: includeMultilineStrings,
                file: file,
                line: line
            ),
            expectedCount,
            file: (file),
            line: line
        )
    }

    private func assertNoViolation(
        in string: String,
        indentationWidth: Int? = nil,
        includeComments: Bool = true,
        includeCompilerDirectives: Bool = true,
        includeMultilineStrings: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await assertViolations(
            in: string,
            equals: 0,
            indentationWidth: indentationWidth,
            includeComments: includeComments,
            includeCompilerDirectives: includeCompilerDirectives,
            includeMultilineStrings: includeMultilineStrings,
            file: file,
            line: line
        )
    }

    private func assert1Violation(
        in string: String,
        indentationWidth: Int? = nil,
        includeComments: Bool = true,
        includeCompilerDirectives: Bool = true,
        includeMultilineStrings: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await assertViolations(
            in: string,
            equals: 1,
            indentationWidth: indentationWidth,
            includeComments: includeComments,
            includeCompilerDirectives: includeCompilerDirectives,
            includeMultilineStrings: includeMultilineStrings,
            file: file,
            line: line
        )
    }
}
