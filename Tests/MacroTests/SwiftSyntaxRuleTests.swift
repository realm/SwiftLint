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
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, locationConverter: file.locationConverter)
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
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, locationConverter: file.locationConverter)
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
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, locationConverter: file.locationConverter)
                }
            }

            extension Hello {
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    file.foldedSyntaxTree
                }
            }
            """,
            macros: macros
        )
    }

    func testArbitraryFoldArgument() {
        // Silently fail because the macro definition explicitly requires a bool
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: variable)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, locationConverter: file.locationConverter)
                }
            }
            """,
            macros: macros
        )
    }
}
