import SwiftLintCore
import Testing

@Suite
struct CommentLinesVisitorTests {
    @Test
    func emptyFile() {
        #expect(commentOnlyLines(in: "").isEmpty)
    }

    @Test
    func singleLineComment() {
        #expect(commentOnlyLines(in: "// This is a comment") == [1])
    }

    @Test
    func multipleSingleLineComments() {
        let contents = """
            // First comment
            // Second comment
            // Third comment
            """
        #expect(commentOnlyLines(in: contents) == [1, 2, 3])
    }

    @Test
    func blockComment() {
        let contents = """
            /*
            * This is a block comment
            * spanning multiple lines
            */
            """
        #expect(commentOnlyLines(in: contents) == [1, 2, 3, 4])
    }

    @Test
    func mixedCommentsAndCode() {
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
        #expect(commentOnlyLines(in: contents) == [1, 4, 6, 9])
    }

    @Test
    func commentsWithWhitespace() {
        let contents = """
                // Comment with leading spaces
            \t// Comment with leading tab
            \t  // Comment with mixed whitespace
            """
        #expect(commentOnlyLines(in: contents) == [1, 2, 3])
    }

    @Test
    func emptyLinesIgnored() {
        let contents = """
            // First comment


            // Second comment after empty lines
            """
        #expect(commentOnlyLines(in: contents) == [1, 4])
    }

    @Test
    func documentationComments() {
        let contents = """
            /// This is a documentation comment
            /// for a function
            /**
            * Block documentation comment
            */
            func test() {}
            """
        #expect(commentOnlyLines(in: contents) == [1, 2, 3, 4, 5])
    }

    @Test
    func inlineCommentsNotCounted() {
        let contents = """
            let x = 5 // This comment is on the same line as code
            print("test") /* inline block comment */
            """
        #expect(commentOnlyLines(in: contents).isEmpty)
    }

    @Test
    func commentBlockStartedOnCodeLine() {
        let contents = """
            print("test") /* block
                             comment */
            """
        #expect(commentOnlyLines(in: contents) == [2])
    }

    @Test
    func complexExample() {
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

        #expect(commentOnlyLines(in: contents) == [1, 2, 3, 4, 5, 9, 11, 14, 15, 16, 17, 19, 23])
    }

    @Test
    func lineNumberAccuracy() {
        let contents = """
            let x = 1
            // Line 2 comment
            let y = 2
            // Line 4 comment
            /* Line 5 block
               Line 6 continuation */
            let z = 3 // Line 7 inline
            """

        #expect(commentOnlyLines(in: contents) == [2, 4, 5, 6])
    }

    private func commentOnlyLines(in contents: String) -> [Int] {
        let file = SwiftLintFile(contents: contents)
        let visitor = CommentLinesVisitor(locationConverter: file.locationConverter)
        visitor.walk(file.syntaxTree)
        return Array(visitor.commentOnlyLines).sorted()
    }
}
