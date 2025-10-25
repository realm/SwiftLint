import SwiftSyntax
import XCTest

@testable import SwiftLintCore

final class EmptyLinesVisitorTests: XCTestCase {
    func testEmptyFile() {
        XCTAssertEqual(emptyLines(in: ""), [])
    }

    func testSingleLineOfCode() {
        XCTAssertEqual(emptyLines(in: "let x = 1"), [])
    }

    func testSingleEmptyLine() {
        let contents = """
            let x = 1

            let y = 2
            """
        XCTAssertEqual(emptyLines(in: contents), [2])
    }

    func testMultipleEmptyLines() {
        let contents = """
            let x = 1


            let y = 2
            """
        XCTAssertEqual(emptyLines(in: contents), [2, 3])
    }

    func testEmptyLinesWithWhitespace() {
        let contents = """
            let x = 1
            \t

            let y = 2
            """
        XCTAssertEqual(emptyLines(in: contents), [2, 3])
    }

    func testNoEmptyLines() {
        let contents = """
            let x = 1
            let y = 2
            let z = 3
            """
        XCTAssertEqual(emptyLines(in: contents), [])
    }

    func testEmptyLinesWithComments() {
        let contents = """
            // Comment

            let x = 1

            // Another comment
            """
        XCTAssertEqual(emptyLines(in: contents), [2, 4])
    }

    func testEmptyLinesWithBlockComments() {
        let contents = """
            /*
             * Block comment
             */

            let x = 1
            """
        XCTAssertEqual(emptyLines(in: contents), [4])
    }

    func testTrailingEmptyLines() {
        let contents = """
            let x = 1


            """
        XCTAssertEqual(emptyLines(in: contents), [2, 3])
    }

    func testLeadingEmptyLines() {
        let contents = """


            let x = 1
            """
        XCTAssertEqual(emptyLines(in: contents), [1, 2])
    }

    func testComplexExample() {
        let contents = """
            // Header comment

            import Foundation

            /// Documentation for the class

            class TestClass {

                // Property comment
                let property: String = "value"

                /**
                * Block documentation comment
                * for the function
                */

                func test() {

                    // Function body comment
                    print("test")

                }

            }

            // Trailing comment

            """
        XCTAssertEqual(emptyLines(in: contents), [2, 4, 6, 8, 11, 16, 18, 21, 23, 25, 27])
    }

    func testMixedEmptyLinesAndContent() {
        let contents = """
            let a = 1

            let b = 2

            // Comment

            let c = 3

            """
        XCTAssertEqual(emptyLines(in: contents), [2, 4, 6, 8])
    }

    func testOnlyEmptyLines() {
        let contents = """



            """
        XCTAssertEqual(emptyLines(in: contents), [1, 2, 3])
    }

    func testEmptyLinesInMultilineString() {
        let contents = """
            let str = \"\"\"
            Line 1

            Line 3
            \"\"\"

            let x = 1
            """
        XCTAssertEqual(emptyLines(in: contents), [6])
    }

    func testLineNumberAccuracy() {
        let contents = """
            let x = 1

            // Line 3 comment

            /* Line 5 block
               Line 6 continuation */

            let z = 3

            """

        XCTAssertEqual(emptyLines(in: contents), [2, 4, 7, 9])
    }

    func testNoTrailingNewline() {
        let contents = "let x = 1"
        XCTAssertEqual(emptyLines(in: contents), [])
    }

    func testOnlyWhitespace() {
        let contents = "\t\n    \n  \t  "
        XCTAssertEqual(emptyLines(in: contents), [1, 2, 3])
    }

    private func emptyLines(in contents: String) -> [Int] {
        EmptyLinesVisitor.emptyLines(in: SwiftLintFile(contents: contents)).sorted()
    }
}
