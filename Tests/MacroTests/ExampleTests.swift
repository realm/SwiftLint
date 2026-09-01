import SwiftLintCore
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import SwiftLintCoreMacros

private let macros = [
    "example": MacroSpec(type: Example.self)
]

@freestanding(expression)
private macro example(body: () -> Void) -> SwiftLintCore.Example = #externalMacro(
    module: "SwiftLintCoreMacros",
    type: "Example"
)

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
                code: \"\"\"
                func f() {
                    print("Hello, world!")
                }
                \"\"\",
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
                code: \"\"\"
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

    @Test
    func exampleCodeIndentation() {
        let example = #example {
            func f() {
                print("Hello, world!")
            }
        }
        let expectedCode = """
        func f() {
            print("Hello, world!")
        }
        """

        #expect(example.code == expectedCode)
    }
}
