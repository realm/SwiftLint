@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "MakeAcceptableByConfigurationElement": MakeAcceptableByConfigurationElement.self
]

// swiftlint:disable:next type_name
final class MakeAcceptableByConfigurationElementTests: XCTestCase {
    func testNoEnum() {
        assertMacroExpansion(
            """
            @MakeAcceptableByConfigurationElement
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
            @MakeAcceptableByConfigurationElement
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
            @MakeAcceptableByConfigurationElement
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
                    if let value = value as? String, let newSelf = Self (rawValue: value) {
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
            @MakeAcceptableByConfigurationElement
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
                    if let value = value as? String, let newSelf = Self (rawValue: value) {
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
