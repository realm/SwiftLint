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

                    guard let configuration = configuration as? [String: Any] else {
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
                var eA = 1
                @ConfigurationElement(value: 7)
                var eB = 2
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement
                var eA = 1
                @ConfigurationElement(value: 7)
                var eB = 2

                mutating func apply(configuration: Any) throws {

                    guard let configuration = configuration as? [String: Any] else {
                        throw Issue.invalidConfiguration(ruleID: Parent.description.identifier)
                    }
                    if $eA.key.isEmpty {
                    $eA.key = "e_a"
                    }
                    try eA.apply(configuration[$eA.key], ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    if $eB.key.isEmpty {
                        $eB.key = "e_b"
                    }
                    try eB.apply(configuration[$eB.key], ruleID: Parent.identifier)
                    try $eB.performAfterParseOperations()
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

    func testInlinedConfigurationElements() {
        assertMacroExpansion(
            """
            @AutoApply
            struct S {
                @ConfigurationElement(key: "eD")
                var eA = 1
                @ConfigurationElement(inline: true)
                var eB = 2
                @ConfigurationElement(inline: false)
                var eC = 3
            }
            """,
            expandedSource:
            """
            struct S {
                @ConfigurationElement(key: "eD")
                var eA = 1
                @ConfigurationElement(inline: true)
                var eB = 2
                @ConfigurationElement(inline: false)
                var eC = 3

                mutating func apply(configuration: Any) throws {
                    do {
                    try eB.apply(configuration, ruleID: Parent.identifier)
                    try $eB.performAfterParseOperations()
                    } catch let issue as Issue where issue == Issue.nothingApplied(ruleID: Parent.identifier) {
                    // Acceptable. Continue.
                }
                    guard let configuration = configuration as? [String: Any] else {
                        return
                    }
                    if $eA.key.isEmpty {
                    $eA.key = "e_a"
                    }
                    try eA.apply(configuration[$eA.key], ruleID: Parent.identifier)
                    try $eA.performAfterParseOperations()
                    if $eC.key.isEmpty {
                        $eC.key = "e_c"
                    }
                    try eC.apply(configuration[$eC.key], ruleID: Parent.identifier)
                    try $eC.performAfterParseOperations()
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
