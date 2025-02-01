import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import SwiftLintCoreMacros

private let macros = [
    "AcceptableByConfigurationElement": MacroSpec(type: AcceptableByConfigurationElement.self)
]

@Suite
struct AcceptableByConfigurationElementTests {
    @Test
    func noEnum() {
        assertMacroExpansion(
            """
            @AcceptableByConfigurationElement
            struct S {
            }
            """,
            expandedSource:
            """
            struct S {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: SwiftLintCoreMacroError.notEnum.message, line: 1, column: 1)
            ],
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func noStringRawType() {
        assertMacroExpansion(
            """
            @AcceptableByConfigurationElement
            enum E {
            }
            """,
            expandedSource:
            """
            enum E {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: SwiftLintCoreMacroError.noStringRawType.message, line: 1, column: 1)
            ],
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func privateEnum() {
        assertMacroExpansion(
            """
            @AcceptableByConfigurationElement
            private enum E: String {
            }
            """,
            expandedSource:
            """
            private enum E: String {
            }

            extension E: AcceptableByConfigurationElement {
                private func asOption() -> OptionType {
                    .symbol(rawValue)
                }
                private init(fromAny value: Any, context ruleID: String) throws(SwiftLintCore.Issue) {
                    if let value = value as? String, let newSelf = Self(rawValue: value) {
                        self = newSelf
                    } else {
                        throw .invalidConfiguration(ruleID: ruleID)
                    }
                }
            }
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }

    @Test
    func publicEnum() {
        assertMacroExpansion(
            """
            @AcceptableByConfigurationElement
            public enum E: String {
            }
            """,
            expandedSource:
            """
            public enum E: String {
            }

            extension E: AcceptableByConfigurationElement {
                public func asOption() -> OptionType {
                    .symbol(rawValue)
                }
                public init(fromAny value: Any, context ruleID: String) throws(SwiftLintCore.Issue) {
                    if let value = value as? String, let newSelf = Self(rawValue: value) {
                        self = newSelf
                    } else {
                        throw .invalidConfiguration(ruleID: ruleID)
                    }
                }
            }
            """,
            macroSpecs: macros,
            failureHandler: FailureHandler.instance
        )
    }
}
