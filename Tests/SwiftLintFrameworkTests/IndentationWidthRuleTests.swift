@testable import SwiftLintFramework
import XCTest

class IndentationWidthRuleTests: XCTestCase {
    // MARK: Examples
    /// It's not okay to have the first line indented.
    func testFirstLineIndentation() async throws {
        try await assert1Violation(in: "    firstLine")
        try await assert1Violation(in: "   firstLine")
        try await assert1Violation(in: " firstLine")
        try await assert1Violation(in: "\tfirstLine")

        try await assertNoViolation(in: "firstLine")
    }

    /// It's not okay to indent using both tabs and spaces in one line.
    func testMixedTabSpaceIndentation() async throws {
        // Expect 2 violations as secondLine is also indented by 8 spaces (which isn't valid)
        try await assertViolations(in: "firstLine\n\t    secondLine", equals: 2)
        try await assertViolations(in: "firstLine\n    \tsecondLine", equals: 2)
    }

    /// It's okay to indent using either tabs or spaces in different lines.
    func testMixedTabsAndSpacesIndentation() async throws {
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n        thirdLine")
        try await assertNoViolation(in: "firstLine\n    secondLine\n\t\tthirdLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n        thirdLine\n\t\t\tfourthLine")
    }

    /// It's okay to keep the same indentation.
    func testKeepingIndentation() async throws {
        try await assertNoViolation(in: "firstLine\nsecondLine")
        try await assertNoViolation(in: "firstLine    \nsecondLine\n    thirdLine")
        try await assertNoViolation(in: "firstLine\t\nsecondLine\n\tthirdLine")
    }

    /// It's only okay to indent using one tab or indentationWidth spaces.
    func testIndentationLength() async throws {
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 1)
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 2)
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 3)
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 4)
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 5)
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 6)
        try await assert1Violation(in: "firstLine\n        secondLine", indentationWidth: 7)
        try await assert1Violation(in: "firstLine\n\t\tsecondLine")
        try await assert1Violation(in: "firstLine\n\t\t\tsecondLine")
        try await assert1Violation(in: "firstLine\n\t\t\t\t\t\tsecondLine")

        try await assertNoViolation(in: "firstLine\n\tsecondLine")
        try await assertNoViolation(in: "firstLine\n secondLine", indentationWidth: 1)
        try await assertNoViolation(in: "firstLine\n  secondLine", indentationWidth: 2)
        try await assertNoViolation(in: "firstLine\n   secondLine", indentationWidth: 3)
        try await assertNoViolation(in: "firstLine\n    secondLine", indentationWidth: 4)
        try await assertNoViolation(in: "firstLine\n     secondLine", indentationWidth: 5)
        try await assertNoViolation(in: "firstLine\n      secondLine", indentationWidth: 6)
        try await assertNoViolation(in: "firstLine\n       secondLine", indentationWidth: 7)
        try await assertNoViolation(in: "firstLine\n        secondLine", indentationWidth: 8)
    }

    /// It's okay to unindent indentationWidth * (1, 2, 3, ...) - x iff x == 0.
    func testUnindentation() async throws {
        try await assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n fourthLine")
        try await assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n  fourthLine")
        try await assert1Violation(in: "firstLine\n    secondLine\n        thirdLine\n   fourthLine")
        try await assert1Violation(in: "firstLine\n    secondLine\n    thirdLine\n   fourthLine")

        try await assertNoViolation(in: "firstLine\n    secondLine\n        thirdLine\nfourthLine")
        try await assertNoViolation(in: "firstLine\n    secondLine\n    thirdLine\nfourthLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n\t\tthirdLine\n\t\t\tfourthLine\nfifthLine")
    }

    /// It's okay to have empty lines between iff the following indentations obey the rules.
    func testEmptyLinesBetween() async throws {
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n\n\tfourthLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n \n\tfourthLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n           \n\tfourthLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n\n    fourthLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n \n    fourthLine")
        try await assertNoViolation(in: "firstLine\n\tsecondLine\n           \n    fourthLine")

        try await assert1Violation(in: "firstLine\n\tsecondLine\n\n\t\t\tfourthLine")
        try await assert1Violation(in: "firstLine\n\tsecondLine\n \n\t\t\tfourthLine")
        try await assert1Violation(in: "firstLine\n\tsecondLine\n           \n\t\t\tfourthLine")
        try await assert1Violation(in: "firstLine\n\tsecondLine\n\n            fourthLine")
        try await assert1Violation(in: "firstLine\n\tsecondLine\n \n            fourthLine")
        try await assert1Violation(in: "firstLine\n\tsecondLine\n           \n            fourthLine")
    }

    func testsBrackets() async throws {
        try await assertNoViolation(
            in: "firstLine\n    [\n        .thirdLine\n    ]\nfifthLine",
            includeComments: true
        )

        try await assertNoViolation(
            in: "firstLine\n    [\n        .thirdLine\n    ]\nfifthLine",
            includeComments: false
        )

        try await assertNoViolation(
            in: "firstLine\n    (\n        .thirdLine\n    )\nfifthLine",
            includeComments: true
        )

        try await assertNoViolation(
            in: "firstLine\n    (\n        .thirdLine\n    )\nfifthLine",
            includeComments: false
        )
    }

    /// It's okay to have comments not following the indentation pattern iff the configuration allows this.
    func testCommentLines() async throws {
        try await assert1Violation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            includeComments: true
        )
        try await assertViolations(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n // test\n//test\n\t\tfourthLine",
            equals: 2,
            includeComments: true
        )
        try await assertViolations(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n/*test\n  bad indent...\n test*/\n\t\tfourthLine",
            equals: 3,
            includeComments: true
        )

        try await assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n\t\tfourthLine",
            includeComments: false
        )
        try await assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n//test\n // test\n//test\n\t\tfourthLine",
            includeComments: false
        )
        try await assertNoViolation(
            in: "firstLine\n\tsecondLine\n\t\tthirdLine\n/*test\n  bad indent...\n test*/\n\t\tfourthLine",
            includeComments: false
        )
    }

    /// Duplicate warnings for one actual indentation issue should be avoided.
    func testDuplicateWarningAvoidanceMechanism() async throws {
        // thirdLine is indented correctly, yet not in-line with the badly indented secondLine. This should be allowed.
        try await assert1Violation(in: "firstLine\n secondLine\nthirdLine")

        // thirdLine is indented correctly, yet not in-line with the badly indented secondLine. This should be allowed.
        try await assert1Violation(in: "firstLine\n     secondLine\n    thirdLine")

        // thirdLine is indented badly, yet in-line with the badly indented secondLine. This should be allowed.
        try await assert1Violation(in: "firstLine\n     secondLine\n     thirdLine")

        // This pattern should go on indefinitely...
        try await assert1Violation(in: "firstLine\n     secondLine\n     thirdLine\n    fourthLine")
        try await assert1Violation(in: "firstLine\n     secondLine\n     thirdLine\n     fourthLine")

        // Still, this won't disable multiple line warnings in one file if suitable...
        try await assertViolations(in: "firstLine\n     secondLine\nthirdLine\n     fourthLine", equals: 2)
        try await assertViolations(in: "firstLine\n     secondLine\n    thirdLine\n     fourthLine", equals: 2)
        try await assertViolations(in: "firstLine\n     secondLine\n     thirdLine\nfourthLine\n     fifthLine",
                                   equals: 2)
        try await assertViolations(in: "firstLine\n     secondLine\n     thirdLine\n    fourthLine\n     fifthLine",
                                   equals: 2)
    }

    func testIgnoredCompilerDirectives() async throws {
        try await assertNoViolation(in: """
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

        try await assertNoViolation(in: """
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

    // MARK: Helpers
    private func countViolations(
        in example: Example,
        indentationWidth: Int? = nil,
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> Int {
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

        guard let config = makeConfig(configDict, IndentationWidthRule.description.identifier) else {
            XCTFail("Unable to create rule configuration.", file: (file), line: line)
            return 0
        }

        return try await violations(example.with(code: example.code + "\n"), config: config).count
    }

    private func assertViolations(
        in string: String,
        equals expectedCount: Int,
        indentationWidth: Int? = nil,
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let actualCount = try await countViolations(
            in: Example(string, file: (file), line: line),
            indentationWidth: indentationWidth,
            includeComments: includeComments,
            includeCompilerDirectives: includeCompilerDirectives,
            file: file,
            line: line
        )
        XCTAssertEqual(actualCount, expectedCount, file: file, line: line)
    }

    private func assertNoViolation(
        in string: String,
        indentationWidth: Int? = nil,
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        try await assertViolations(
            in: string,
            equals: 0,
            indentationWidth: indentationWidth,
            includeComments: includeComments,
            includeCompilerDirectives: includeCompilerDirectives,
            file: file,
            line: line
        )
    }

    private func assert1Violation(
        in string: String,
        indentationWidth: Int? = nil,
        includeComments: Bool? = nil,
        includeCompilerDirectives: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        try await assertViolations(
            in: string,
            equals: 1,
            indentationWidth: indentationWidth,
            includeComments: includeComments,
            includeCompilerDirectives: includeCompilerDirectives,
            file: file,
            line: line
        )
    }
}
