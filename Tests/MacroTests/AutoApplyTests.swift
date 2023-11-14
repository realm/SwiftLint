@testable import SwiftLintCoreMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

private let macros = [
    "AutoApply": AutoApply.self
]

final class AutoApplyTests: XCTestCase {
    func testAttachToClass() {
        assertMacroExpansion(
            """
            @AutoApply
            class C {
            }
            """,
            expandedSource:
            """
            class C {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: SwiftLintCoreMacroError.notStruct.message, line: 1, column: 1)
            ],
            macros: macros)
    }

    func testNoConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoApply
            struct S {
            }
            """,
            expandedSource:
            """
            struct S {

                mutating func apply(configuration: Any) throws {

                    guard let _ = configuration as? [String: Any] else {
                        throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                    }

                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testConfigurationElementsWithoutKeys() {
        assertMacroExpansion(
            """
            @AutoApply
            struct S {
                @ConfigurationElement
                var e1 = 1
                @ConfigurationElement(value: 7)
                var e2 = 2
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement
                var e1 = 1
                @ConfigurationElement(value: 7)
                var e2 = 2

                mutating func apply(configuration: Any) throws {
                    try e1.apply(configuration, ruleID: Parent.identifier)
                    try e2.apply(configuration, ruleID: Parent.identifier)
                    guard let _ = configuration as? [String: Any] else {
                        return
                    }

                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testConfigurationElementsWithKeys() {
        assertMacroExpansion(
            """
            @AutoApply
            struct S {
                @ConfigurationElement(key: "e1")
                var e1 = 1
                @ConfigurationElement(key: "e2", other: 7)
                var e2 = 2
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement(key: "e1")
                var e1 = 1
                @ConfigurationElement(key: "e2", other: 7)
                var e2 = 2

                mutating func apply(configuration: Any) throws {

                    guard let configuration = configuration as? [String: Any] else {
                        throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                    }
                    try e1.apply(configuration[$e1.key], ruleID: Parent.identifier)
                    try $e1.performAfterParseOperations()
                    try e2.apply(configuration[$e2.key], ruleID: Parent.identifier)
                    try $e2.performAfterParseOperations()
                    if !supportedKeys.isSuperset(of: configuration.keys) {
                        let unknownKeys = Set(configuration.keys).subtracting(supportedKeys)
                        throw Issue.invalidConfigurationKeys(ruleID: Parent.identifier, keys: unknownKeys)
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
