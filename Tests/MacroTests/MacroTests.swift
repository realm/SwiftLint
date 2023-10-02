@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MacroTests: XCTestCase {
    func testFold() {
        assertMacroExpansion(
            """
            @Fold
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello {
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    file.foldedSyntaxTree
                }
            }
            """,
            macros: [
                "Fold": Fold.self
            ]
        )
    }

    func testSwiftSyntaxRule() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
                    Visitor(viewMode: .sourceAccurate)
                }
            }
            """,
            macros: [
                "SwiftSyntaxRule": SwiftSyntaxRule.self
            ]
        )
    }
}
