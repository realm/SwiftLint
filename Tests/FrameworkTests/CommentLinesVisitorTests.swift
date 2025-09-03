@testable import SwiftLintCore
import XCTest

final class CommentLinesVisitorTests: XCTestCase {
    func testEmptyFile() {
        XCTAssertEqual(commentOnlyLines(in: ""), [])
    }

    func testSingleLineComment() {
        XCTAssertEqual(commentOnlyLines(in: "// This is a comment"), [1])
    }

    func testMultipleSingleLineComments() {
        let contents = """
            // First comment
            // Second comment
            // Third comment
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [1, 2, 3])
    }

    func testBlockComment() {
        let contents = """
            /*
            * This is a block comment
            * spanning multiple lines
            */
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [1, 2, 3, 4])
    }

    func testMixedCommentsAndCode() {
        let contents = """
            // Comment at the top
            import Foundation

            // Another comment
            func test() {
                // Inline comment
                print("Hello")
            }
            // Final comment
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [1, 4, 6, 9])
    }

    func testCommentsWithWhitespace() {
        let contents = """
                // Comment with leading spaces
            \t// Comment with leading tab
            \t  // Comment with mixed whitespace
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [1, 2, 3])
    }

    func testEmptyLinesIgnored() {
        let contents = """
            // First comment


            // Second comment after empty lines
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [1, 4])
    }

    func testDocumentationComments() {
        let contents = """
            /// This is a documentation comment
            /// for a function
            /**
            * Block documentation comment
            */
            func test() {}
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [1, 2, 3, 4, 5])
    }

    func testInlineCommentsNotCounted() {
        let contents = """
            let x = 5 // This comment is on the same line as code
            print("test") /* inline block comment */
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [])
    }

    func testCommentBlockStartedOnCodeLine() {
        let contents = """
            print("test") /* block
                             comment */
            """
        XCTAssertEqual(commentOnlyLines(in: contents), [2])
    }

    func testComplexExample() {
        let contents = """
            // Header comment
            /*
            * Multi-line block comment
            * with multiple lines
            */

            import Foundation

            /// Documentation for the class
            class TestClass {
                // Property comment
                let property: String = "value" // inline comment doesn't count

                /**
                * Block documentation comment
                * for the function
                */
                func test() {
                    // Function body comment
                }
            }

            // Trailing comment
            """

        XCTAssertEqual(commentOnlyLines(in: contents), [1, 2, 3, 4, 5, 9, 11, 14, 15, 16, 17, 19, 23])
    }

    func testLineNumberAccuracy() {
        let contents = """
            let x = 1
            // Line 2 comment
            let y = 2
            // Line 4 comment
            /* Line 5 block
               Line 6 continuation */
            let z = 3 // Line 7 inline
            """

        XCTAssertEqual(commentOnlyLines(in: contents), [2, 4, 5, 6])
    }

    private func commentOnlyLines(in contents: String) -> [Int] {
        let file = SwiftLintFile(contents: contents)
        let visitor = CommentLinesVisitor(locationConverter: file.locationConverter)
        visitor.walk(file.syntaxTree)
        return Array(visitor.commentOnlyLines).sorted()
    }
}
