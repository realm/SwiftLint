import SwiftLintCore
import SwiftParser
import SwiftSyntax
import XCTest

final class CodeIndentingRewriterTests: XCTestCase {
    func testIndentDefaultStyle() {
        assertIndent(
            source: """
                if c {
                    // comment
                    return 1
                    // another comment
                }
                """,
            indentedSource: """
                if c {
                    // comment
                    return 1
                    // another comment
                }
            """,
            style: .indentSpaces(4)
        )
    }

    func testIndentThreeSpaces() {
        assertIndent(
            source: """
                 if c {
                       // comment
                     return 1
                     // another comment
                 }
                """,
            indentedSource: """
                if c {
                      // comment
                    return 1
                    // another comment
                }
            """,
            style: .indentSpaces(3)
        )
    }

    func testIndentTabs() {
        assertIndent(
            source: """
                if c {
                    // comment
                    return 1
                       // another comment
                }
                """,
            indentedSource: """
            \tif c {
            \t    // comment
            \t    return 1
            \t       // another comment
            \t}
            """,
            style: .indentTabs(1)
        )
    }

    func testIndentCodeBlock() {
        assertIndent(
            source: """
                // initial comment
                {
                    if c {
                        // comment
                        return 1
                        // another comment
                    }
                    // yet another comment
                }
                """,
            indentedSource: """
                    // initial comment
                    {
                        if c {
                            // comment
                            return 1
                            // another comment
                        }
                        // yet another comment
                    }
                """,
            style: .indentSpaces(4)
        )
    }

    func testUnindentDefaultStyle() {
        assertIndent(
            source: """
                if c {
                    // comment
                    return 1
                    // another comment
                }
            """,
            indentedSource: """
                if c {
                    // comment
                    return 1
                    // another comment
                }
                """,
            style: .unindentSpaces(4)
        )
    }

    func testUnindentTwoSpaces() {
        assertIndent(
            source: """
              if c {
                   // comment
                  return 1
                  // another comment
              }
            """,
            indentedSource: """
                if c {
                     // comment
                    return 1
                    // another comment
                }
                """,
            style: .unindentSpaces(2)
        )
    }

    func testUnindentTabs() {
        assertIndent(
            source: """
            \tif c {
            \t\t   // comment
            \t\treturn 1
            \t\t\t// another comment
            \t}
            """,
            indentedSource: """
                if c {
                \t   // comment
                \treturn 1
                \t\t// another comment
                }
                """,
            style: .unindentTabs(1)
        )
    }

    private func assertIndent(source: String, indentedSource: String, style: CodeIndentingRewriter.IndentationStyle) {
        let rewritten = CodeIndentingRewriter(style: style).rewrite(Parser.parse(source: source))
        XCTAssertEqual(rewritten.description, indentedSource)
    }
}
