import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import SwiftLintCoreMacros

private let macros = [
    "example": MacroSpec(type: Example.self)
]

@Suite
struct ExampleTests {
    @Test
    func exampleMacro() {
        assertMacroExpansion(
            """
            #example {
                func f() {
                    print("Hello, world!")
                }
            }
            """,
            expandedSource: """
            Example(
                \"\"\"
                func f() {
                    print("Hello, world!")
                }
                \"\"\",
                configuration: [:],
                testMultiByteOffsets: true,
                testWrappingInComment: true,
                testWrappingInString: true,
                testDisableCommand: true,
                testOnLinux: true,
                testOnWindows: true,
                excludeFromDocumentation: false,
                fileID: "TestModule/test.swift",
                file: "test.swift",
                line: 1
            )
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func exampleMacroWithConfiguration() {
        assertMacroExpansion(
            """
            #example(
                configuration: ["severity": "warning"],
                testMultiByteOffsets: false,
                testWrappingInComment: false,
                testWrappingInString: false,
                testDisableCommand: false,
                testOnLinux: false,
                testOnWindows: false,
                excludeFromDocumentation: true
            ) {
                print("Hello, world!")
            }
            """,
            expandedSource: """
            Example(
                \"\"\"
                print("Hello, world!")
                \"\"\",
                configuration: ["severity": "warning"],
                testMultiByteOffsets: false,
                testWrappingInComment: false,
                testWrappingInString: false,
                testDisableCommand: false,
                testOnLinux: false,
                testOnWindows: false,
                excludeFromDocumentation: true,
                fileID: "TestModule/test.swift",
                file: "test.swift",
                line: 1
            )
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }
}
