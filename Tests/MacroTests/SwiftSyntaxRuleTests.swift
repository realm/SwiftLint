@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "SwiftSyntaxRule": SwiftSyntaxRule.self
]

final class SwiftSyntaxRuleTests: XCTestCase {
    func testNoArguments() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, file: file)
                }
            }
            """,
            macros: macros
        )
    }

    func testFalseArguments() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: false, explicitRewriter: false)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, file: file)
                }
            }
            """,
            macros: macros
        )
    }

    func testTrueArguments() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, file: file)
                }
            }

            extension Hello {
                func preprocess(file: SwiftLintFile) -> SourceFileSyntax? {
                    file.foldedSyntaxTree
                }
            }

            extension Hello: SwiftSyntaxCorrectableRule {
                func makeRewriter(file: SwiftLintFile) -> (some ViolationsSyntaxRewriter)? {
                    Rewriter(locationConverter: file.locationConverter, disabledRegions: disabledRegions(file: file))
                }
            }
            """,
            macros: macros
        )
    }

    func testArbitraryArguments() {
        // Silently fail because the macro definition explicitly requires a bool arguments.
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: variable, explicitRewriter: variable)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, file: file)
                }
            }
            """,
            macros: macros
        )
    }
}
