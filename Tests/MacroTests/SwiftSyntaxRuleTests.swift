@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "SwiftSyntaxRule": SwiftSyntaxRule.self
]

final class SwiftSyntaxRuleTests: XCTestCase {
    func testNoFoldArgument() {
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
            macros: macros
        )
    }

    func testFalseFoldArgument() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: false)
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
            macros: macros
        )
    }

    func testTrueFoldArgument() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: true)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
                    Visitor(viewMode: .sourceAccurate)
                }
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    file.foldedSyntaxTree
                }
            }
            """,
            macros: macros
        )
    }

    func testArbitraryFoldArgument() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: variable)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
                    Visitor(viewMode: .sourceAccurate)
                }
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    if variable {
                        file.foldedSyntaxTree
                    } else {
                        nil
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
