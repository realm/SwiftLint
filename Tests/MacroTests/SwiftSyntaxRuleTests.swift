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
            @SwiftSyntaxRule(foldExpressions: false, explicitRewriter: false, correctable: false, optIn: false)
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
            @SwiftSyntaxRule(foldExpressions: true, explicitRewriter: true, correctable: true, optIn: true)
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
                func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter<ConfigurationType>? {
                    Rewriter(configuration: configuration, file: file)
                }
            }

            extension Hello: OptInRule {
            }
            """,
            macros: macros
        )
    }

    func testCorrectableWithoutExplcitRewriter() {
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(correctable: true)
            struct Hello {}
            """,
            expandedSource: """
            struct Hello {}

            extension Hello: SwiftSyntaxRule {
                func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor<ConfigurationType> {
                    Visitor(configuration: configuration, file: file)
                }
            }

            extension Hello: SwiftSyntaxCorrectableRule {
            }
            """,
            macros: macros
        )
    }

    func testArbitraryArguments() {
        // Fail with a diagnostic because the macro definition explicitly requires bool arguments.
        assertMacroExpansion(
            """
            @SwiftSyntaxRule(foldExpressions: arg, explicitRewriter: arg, correctable: arg, optIn: arg)
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
            diagnostics: [
                DiagnosticSpec(message: SwiftLintCoreMacroError.noBooleanLiteral.message, line: 1, column: 35),
                DiagnosticSpec(message: SwiftLintCoreMacroError.noBooleanLiteral.message, line: 1, column: 58),
                DiagnosticSpec(message: SwiftLintCoreMacroError.noBooleanLiteral.message, line: 1, column: 76),
                DiagnosticSpec(message: SwiftLintCoreMacroError.noBooleanLiteral.message, line: 1, column: 88),
            ],
            macros: macros
        )
    }
}
