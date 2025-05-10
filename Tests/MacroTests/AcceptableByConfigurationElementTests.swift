@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "AcceptableByConfigurationElement": AcceptableByConfigurationElement.self
]

final class AcceptableByConfigurationElementTests: XCTestCase {
    func testNoEnum() {
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
            macros: macros)
    }

    func testNoStringRawType() {
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
            macros: macros)
    }

    func testPrivateEnum() {
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
                private init(fromAny value: Any, context ruleID: String) throws {
                    if let value = value as? String, let newSelf = Self(rawValue: value) {
                        self = newSelf
                    } else {
                        throw Issue.invalidConfiguration(ruleID: ruleID)
                    }
                }
            }
            """,
            macros: macros)
    }

    func testPublicEnum() {
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
                public init(fromAny value: Any, context ruleID: String) throws {
                    if let value = value as? String, let newSelf = Self(rawValue: value) {
                        self = newSelf
                    } else {
                        throw Issue.invalidConfiguration(ruleID: ruleID)
                    }
                }
            }
            """,
            macros: macros)
    }
}
