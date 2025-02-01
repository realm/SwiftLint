import SwiftLintCore
import SwiftParser
import SwiftSyntax
import Testing

@Suite
struct CodeIndentingRewriterTests {
    @Test
    func indentDefaultStyle() {
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

    @Test
    func indentThreeSpaces() {
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

    @Test
    func indentTabs() {
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

    @Test
    func indentCodeBlock() {
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

    @Test
    func unindentDefaultStyle() {
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

    @Test
    func unindentTwoSpaces() {
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

    @Test
    func unindentTabs() {
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
        #expect(rewritten.description == indentedSource)
    }
}
