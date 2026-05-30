import SwiftSyntax
import Testing

@testable import SwiftLintCore

@Suite
struct EmptyLinesVisitorTests {
    @Test
    func emptyFile() {
        #expect(emptyLines(in: "").isEmpty)
    }

    @Test
    func singleLineOfCode() {
        #expect(emptyLines(in: "let x = 1").isEmpty)
    }

    @Test
    func singleEmptyLine() {
        let contents = """
            let x = 1

            let y = 2
            """
        #expect(emptyLines(in: contents) == [2])
    }

    @Test
    func multipleEmptyLines() {
        let contents = """
            let x = 1


            let y = 2
            """
        #expect(emptyLines(in: contents) == [2, 3])
    }

    @Test
    func emptyLinesWithWhitespace() {
        let contents = """
            let x = 1
            \t

            let y = 2
            """
        #expect(emptyLines(in: contents) == [2, 3])
    }

    @Test
    func noEmptyLines() {
        let contents = """
            let x = 1
            let y = 2
            let z = 3
            """
        #expect(emptyLines(in: contents).isEmpty)
    }

    @Test
    func emptyLinesWithComments() {
        let contents = """
            // Comment

            let x = 1

            // Another comment
            """
        #expect(emptyLines(in: contents) == [2, 4])
    }

    @Test
    func emptyLinesWithBlockComments() {
        let contents = """
            /*
             * Block comment
             */

            let x = 1
            """
        #expect(emptyLines(in: contents) == [4])
    }

    @Test
    func trailingEmptyLines() {
        let contents = """
            let x = 1


            """
        #expect(emptyLines(in: contents) == [2, 3])
    }

    @Test
    func leadingEmptyLines() {
        let contents = """


            let x = 1
            """
        #expect(emptyLines(in: contents) == [1, 2])
    }

    @Test
    func complexExample() {
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
        #expect(emptyLines(in: contents) == [2, 4, 6, 8, 11, 16, 18, 21, 23, 25, 27])
    }

    @Test
    func mixedEmptyLinesAndContent() {
        let contents = """
            let a = 1

            let b = 2

            // Comment

            let c = 3

            """
        #expect(emptyLines(in: contents) == [2, 4, 6, 8])
    }

    @Test
    func onlyEmptyLines() {
        let contents = """



            """
        #expect(emptyLines(in: contents) == [1, 2, 3])
    }

    @Test
    func emptyLinesInMultilineString() {
        let contents = """
            let str = \"\"\"
            Line 1

            Line 3
            \"\"\"

            let x = 1
            """
        #expect(emptyLines(in: contents) == [6])
    }

    @Test
    func lineNumberAccuracy() {
        let contents = """
            let x = 1

            // Line 3 comment

            /* Line 5 block
               Line 6 continuation */

            let z = 3

            """

        #expect(emptyLines(in: contents) == [2, 4, 7, 9])
    }

    @Test
    func noTrailingNewline() {
        let contents = "let x = 1"
        #expect(emptyLines(in: contents).isEmpty)
    }

    @Test
    func onlyWhitespace() {
        let contents = "\t\n    \n  \t  "
        #expect(emptyLines(in: contents) == [1, 2, 3])
    }

    private func emptyLines(in contents: String) -> [Int] {
        EmptyLinesVisitor.emptyLines(in: SwiftLintFile(contents: contents)).sorted()
    }
}
