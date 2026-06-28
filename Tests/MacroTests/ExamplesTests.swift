import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import SwiftLintCoreMacros

private let macros = [
    "examples": MacroSpec(type: Examples.self),
    "examplesDictionary": MacroSpec(type: ExamplesDictionary.self),
]

@Suite
struct ExamplesTests {
    @Test
    func expandsExamplesCapturingLines() {
        assertMacroExpansion(
            #"""
            #examples([
                "let x = 1",
                """
                func f() {}
                """,
            ])
            """#,
            expandedSource: #"""
            [
                Example("let x = 1", fileID: "TestModule/test.swift", file: "test.swift", line: 2),
                Example("""
                func f() {}
                """, fileID: "TestModule/test.swift", file: "test.swift", line: 3),
            ]
            """#,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func preservesArrayNewlines() {
        // Each element stays on its own line in the expansion so it is readable when expanded.
        assertMacroExpansion(
            """
            #examples([
                "a",
                "b",
                "c",
            ])
            """,
            expandedSource: """
            [
                Example("a", fileID: "TestModule/test.swift", file: "test.swift", line: 2),
                Example("b", fileID: "TestModule/test.swift", file: "test.swift", line: 3),
                Example("c", fileID: "TestModule/test.swift", file: "test.swift", line: 4),
            ]
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func expandsEmptyArray() {
        assertMacroExpansion(
            """
            #examples([])
            """,
            expandedSource: """
            []
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func nonArrayLiteralArgument() {
        assertMacroExpansion(
            """
            #examples(someExamples)
            """,
            expandedSource: """
            []
            """,
            diagnostics: [
                DiagnosticSpec(message: SwiftLintCoreMacroError.examplesNotArrayLiteral.message, line: 1, column: 1)
            ],
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func expandsDictionaryCapturingLines() {
        // swiftlint:disable line_length
        assertMacroExpansion(
            """
            #examplesDictionary([
                "↓x": "y",
                "↓a": "b",
            ])
            """,
            expandedSource: """
            [
                Example("↓x", fileID: "TestModule/test.swift", file: "test.swift", line: 2): Example("y", fileID: "TestModule/test.swift", file: "test.swift", line: 2),
                Example("↓a", fileID: "TestModule/test.swift", file: "test.swift", line: 3): Example("b", fileID: "TestModule/test.swift", file: "test.swift", line: 3),
            ]
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
        // swiftlint:enable line_length
    }

    @Test
    func expandsEmptyDictionary() {
        assertMacroExpansion(
            """
            #examplesDictionary([:])
            """,
            expandedSource: """
            [:]
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func nonDictionaryLiteralArgument() {
        assertMacroExpansion(
            """
            #examplesDictionary(someDictionary)
            """,
            expandedSource: """
            [:]
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: SwiftLintCoreMacroError.examplesNotDictionaryLiteral.message,
                    line: 1,
                    column: 1
                ),
            ],
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func expandsNonLiteralExamples() {
        // Elements need not be string literals; any `String`-typed expression is wrapped as-is.
        assertMacroExpansion(
            """
            #examples([
                code,
                makeCode(for: rule),
            ])
            """,
            expandedSource: """
            [
                Example(code, fileID: "TestModule/test.swift", file: "test.swift", line: 2),
                Example(makeCode(for: rule), fileID: "TestModule/test.swift", file: "test.swift", line: 3),
            ]
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func expandsNonLiteralDictionary() {
        // Keys and values need not be string literals; any `String`-typed expression is wrapped as-is.
        // swiftlint:disable line_length
        assertMacroExpansion(
            """
            #examplesDictionary([
                trigger: corrected,
                makeCode(for: rule): fixed + suffix,
            ])
            """,
            expandedSource: """
            [
                Example(trigger, fileID: "TestModule/test.swift", file: "test.swift", line: 2): Example(corrected, fileID: "TestModule/test.swift", file: "test.swift", line: 2),
                Example(makeCode(for: rule), fileID: "TestModule/test.swift", file: "test.swift", line: 3): Example(fixed + suffix, fileID: "TestModule/test.swift", file: "test.swift", line: 3),
            ]
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
        // swiftlint:enable line_length
    }
}
