@testable import SwiftLintFramework
import XCTest

class IndentationWidthRuleTests: XCTestCase {
    // MARK: Examples
    /// It's not okay to have the first line indented.
    func testFirstLineIndentation() {
        assert1Violation(in: "    firstLine")
        assert1Violation(in: "   firstLine")
        assert1Violation(in: " firstLine")
        assert1Violation(in: "\tfirstLine")

        assertNoViolation(in: "firstLine")
    }

    /// It's not okay to indent using both tabs and spaces in one line.
    func testMixedTabSpaceIndentation() {
        // Expect 2 violations as secondLine is also indented by 8 spaces (which isn't valid)
        assertViolations(in: "firstLine\n\t    secondLine", equals: 2)
        assertViolations(in: "firstLine\n    \tsecondLine", equals: 2)
    }

    /// It's okay to indent using either tabs or spaces in different lines.
    func testMixedTabsAndSpacesIndentation() {
        assertNoViolation(in: "firstLine\n\tsecondLine\n        thirdLine")
        assertNoViolation(in: "firstLine\n    secondLine\n\t\tthirdLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n        thirdLine\n\t\t\tfourthLine")
    }

    /// It's okay to keep the same indentation.
    func testKeepingIndentation() {
        assertNoViolation(in: "firstLine\nsecondLine")
        assertNoViolation(in: "firstLine    \nsecondLine\n    thirdLine")
        assertNoViolation(in: "firstLine\t\nsecondLine\n\tthirdLine")
    }

    /// It's only okay to indent using one tab or indentationWidth spaces.
    func testIndentationLength() {
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 1)
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 2)
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 3)
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 4)
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 5)
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 6)
        assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 7)
        assert1Violation(in: "firstLine\n\t\tsecondLine")
        assert1Violation(in: "firstLine\n\t\t\tsecondLine")
        assert1Violation(in: "firstLine\n\t\t\t\t\t\tsecondLine")

        assertNoViolation(in: "firstLine\n\tsecondLine")
        assertNoViolation(in: "firstLine\n secondLine", indentationWidth: 1)
        assertNoViolation(in: "firstLine\n  secondLine", indentationWidth: 2)
        assertNoViolation(in: "firstLine\n   secondLine", indentationWidth: 3)
        assertNoViolation(in: "firstLine\n    secondLine", indentationWidth: 4)
        assertNoViolation(in: "firstLine\n     secondLine", indentationWidth: 5)
        assertNoViolation(in: "firstLine\n      secondLine", indentationWidth: 6)
        assertNoViolation(in: "firstLine\n       secondLine", indentationWidth: 7)
        assertNoViolation(in: "firstLine\n        secondLine", indentationWidth: 8)
    }

    /// It's okay to unindent indentationWidth * (1, 2, 3, ...) - x iff x == 0.
    func testUnindentation() {
        assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n fourthLine")
        assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n  fourthLine")
        assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n   fourthLine")
        assert1Violation(in: "firstLine\n    secondLine\n    thirdLine\n   fourthLine")

        assertNoViolation(in: "firstLine\n    secondLine\n        thirdLine\nfourthLine")
        assertNoViolation(in: "firstLine\n    secondLine\n    thirdLine\nfourthLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n\t\tthirdLine\n\t\t\tfourthLine\nfifthLine")
    }

    /// It's okay to have empty lines between iff the following indentations obey the rules.
    func testEmptyLinesBetween() {
        assertNoViolation(in: "firstLine\n\tsecondLine\n\n\tfourthLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n \n\tfourthLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n           \n\tfourthLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n\n    fourthLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n \n    fourthLine")
        assertNoViolation(in: "firstLine\n\tsecondLine\n           \n    fourthLine")

        assert1Violation(in: "firstLine\n\tsecondLine\n\n\t\t\tfourthLine")
        assert1Violation(in: "firstLine\n\tsecondLine\n \n\t\t\tfourthLine")
        assert1Violation(in: "firstLine\n\tsecondLine\n           \n\t\t\tfourthLine")
        assert1Violation(in: "firstLine\n\tsecondLine\n\n            fourthLine")
        assert1Violation(in: "firstLine\n\tsecondLine\n \n            fourthLine")
        assert1Violation(in: "firstLine\n\tsecondLine\n           \n            fourthLine")
    }

    func testsBrackets() {
        assertNoViolation(
            in: "firstLine\n    [\n        .thirdLine\n    ]\nfifthLine",
            includeComments: true
        )

        assertNoViolation(
            in: "firstLine\n    [\n        .thirdLine\n    ]\nfifthLine",
            includeComments: false
        )

        assertNoViolation(
            in: "firstLine\n    (\n        .thirdLine\n    )\nfifthLine",
            includeComments: true
        )

        assertNoViolation(
            in: "firstLine\n    (\n        .thirdLine\n    )\nfifthLine",
            includeComments: false
        )
    }

    /// It's okay to have comments not following the indentation pattern iff the configuration allows this.
    func testCommentLines() {
        assert1Violation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            includeComments: true
        )
        assertViolations(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n // test\n//test\n\t\tfourthLine",
            equals: 2,
            includeComments: true
        )
        assertViolations(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n/*test\n  bad indent...\n test*/\n\t\tfourthLine",
            equals: 3,
            includeComments: true
        )

        assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            includeComments: false
        )
        assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n // test\n//test\n\t\tfourthLine",
            includeComments: false
        )
        assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n/*test\n  bad indent...\n test*/\n\t\tfourthLine",
            includeComments: false
        )
    }

    /// Duplicate warnings for one actual indentation issue should be avoided.
    func testDuplicateWarningAvoidanceMechanism() {
        // thirdLine is indented correctly, yet not in-line with the badly indented secondLine. This should be allowed.
        assert1Violation(in: "firstLine\n secondLine\nthirdLine")

        // thirdLine is indented correctly, yet not in-line with the badly indented secondLine. This should be allowed.
        assert1Violation(in: "firstLine\n     secondLine\n    thirdLine")

        // thirdLine is indented badly, yet in-line with the badly indented secondLine. This should be allowed.
        assert1Violation(in: "firstLine\n     secondLine\n     thirdLine")

        // This pattern should go on indefinitely...
        assert1Violation(in: "firstLine\n     secondLine\n     thirdLine\n    fourthLine")
        assert1Violation(in: "firstLine\n     secondLine\n     thirdLine\n     fourthLine")

        // Still, this won't disable multiple line warnings in one file if suitable...
        assertViolations(in: "firstLine\n     secondLine\nthirdLine\n     fourthLine", equals: 2)
        assertViolations(in: "firstLine\n     secondLine\n    thirdLine\n     fourthLine", equals: 2)
        assertViolations(in: "firstLine\n     secondLine\n     thirdLine\nfourthLine\n     fifthLine", equals: 2)
        assertViolations(in: "firstLine\n     secondLine\n     thirdLine\n    fourthLine\n     fifthLine", equals: 2)
    }

    func testIgnoredCompilerDirectives() {
        assertNoViolation(in: """
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

        assertNoViolation(in: """
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

    func testIgnoredMultilineStrings() {
        assertNoViolation(
            in: "let x = \"\"\"\nstring1\n    string2\n  string3\n\"\"\"\n",
            includeMultilineStrings: false
        )
        assert1Violation(
            in: "let x = \"\"\"\nstring1\n    string2\n  string3\n\"\"\"\n"
        )
        assertViolations(
            in: "let x = \"\"\"\nstring1\n    string2\n  string3\n string4\n\"\"\"\n",
            equals: 2
        )
    }

    // MARK: Helpers
    private func countViolations(
        in example: Example,
        indentationWidth: Int? = nil,
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        includeMultilineStrings: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Int {
        var configDict: [String: Any] = [:]
        if let indentationWidth {
            configDict["indentation_width"] = indentationWidth
        }
        if let includeComments {
            configDict["include_comments"] = includeComments
        }
        if let includeCompilerDirectives {
            configDict["include_compiler_directives"] = includeCompilerDirectives
        }
        if let includeMultilineStrings {
            configDict["include_multiline_strings"] = includeMultilineStrings
        }

        guard let config = makeConfig(configDict, IndentationWidthRule.description.identifier) else {
            XCTFail("Unable to create rule configuration.", file: (file), line: line)
            return 0
        }

        return violations(example.with(code: example.code + "\n"), config: config).count
    }

    private func assertViolations(
        in string: String,
        equals expectedCount: Int,
        indentationWidth: Int? = nil,
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        includeMultilineStrings: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(
            countViolations(
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
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        includeMultilineStrings: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertViolations(
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
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        includeMultilineStrings: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertViolations(
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
